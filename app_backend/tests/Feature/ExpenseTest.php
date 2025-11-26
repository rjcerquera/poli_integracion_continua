<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Expense;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ExpenseTest extends TestCase
{
    use RefreshDatabase;

    private User $user;
    private string $token;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create();
        $this->token = $this->user->createToken('auth_token')->plainTextToken;
    }

    /**
     * Test authenticated user can list their expenses
     */
    public function test_authenticated_user_can_list_expenses(): void
    {
        Expense::factory()->count(3)->create(['user_id' => $this->user->id]);
        Expense::factory()->count(2)->create(); // Other user's expenses

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->getJson('/api/expenses');

        $response->assertStatus(200)
            ->assertJsonCount(3)
            ->assertJsonStructure([
                '*' => [
                    'id',
                    'amount',
                    'description',
                    'date',
                    'category_id',
                    'user_id',
                    'category',
                    'created_at',
                    'updated_at',
                ],
            ]);
    }

    /**
     * Test expenses are ordered by date descending
     */
    public function test_expenses_are_ordered_by_date_descending(): void
    {
        $expense1 = Expense::factory()->create([
            'user_id' => $this->user->id,
            'date' => '2025-01-01',
        ]);
        $expense2 = Expense::factory()->create([
            'user_id' => $this->user->id,
            'date' => '2025-01-03',
        ]);
        $expense3 = Expense::factory()->create([
            'user_id' => $this->user->id,
            'date' => '2025-01-02',
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->getJson('/api/expenses');

        $response->assertStatus(200);
        $expenses = $response->json();
        
        $this->assertEquals($expense2->id, $expenses[0]['id']);
        $this->assertEquals($expense3->id, $expenses[1]['id']);
        $this->assertEquals($expense1->id, $expenses[2]['id']);
    }

    /**
     * Test unauthenticated user cannot list expenses
     */
    public function test_unauthenticated_user_cannot_list_expenses(): void
    {
        $response = $this->getJson('/api/expenses');

        $response->assertStatus(401);
    }

    /**
     * Test authenticated user can create an expense
     */
    public function test_authenticated_user_can_create_expense(): void
    {
        $expenseData = [
            'amount' => 50.99,
            'description' => 'Compra en supermercado',
            'date' => '2025-10-29',
        ];

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson('/api/expenses', $expenseData);

        $response->assertStatus(201)
            ->assertJson([
                'amount' => '50.99',
                'description' => 'Compra en supermercado',
                'user_id' => $this->user->id,
            ]);

        // Verificar estructura básica (category_id puede estar o no, dependiendo de la serialización)
        $responseData = $response->json();
        $this->assertArrayHasKey('id', $responseData);
        $this->assertArrayHasKey('amount', $responseData);
        $this->assertArrayHasKey('description', $responseData);
        $this->assertArrayHasKey('date', $responseData);
        $this->assertArrayHasKey('user_id', $responseData);
        
        // category_id puede estar presente como null o no estar presente
        if (isset($responseData['category_id'])) {
            $this->assertNull($responseData['category_id']);
        }

        $this->assertDatabaseHas('expenses', [
            'amount' => 50.99,
            'description' => 'Compra en supermercado',
            'user_id' => $this->user->id,
        ]);
    }

    /**
     * Test authenticated user can create expense with category
     */
    public function test_authenticated_user_can_create_expense_with_category(): void
    {
        $category = Category::factory()->create(['user_id' => $this->user->id]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson('/api/expenses', [
                'amount' => 100.00,
                'date' => '2025-10-29',
                'category_id' => $category->id,
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'category_id' => $category->id,
            ]);

        $this->assertDatabaseHas('expenses', [
            'category_id' => $category->id,
            'user_id' => $this->user->id,
        ]);
    }

    /**
     * Test authenticated user cannot create expense with other user's category
     */
    public function test_authenticated_user_cannot_create_expense_with_other_user_category(): void
    {
        $otherUser = User::factory()->create();
        $category = Category::factory()->create(['user_id' => $otherUser->id]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson('/api/expenses', [
                'amount' => 100.00,
                'date' => '2025-10-29',
                'category_id' => $category->id,
            ]);

        $response->assertStatus(403)
            ->assertJson([
                'message' => 'Invalid category',
            ]);
    }

    /**
     * Test authenticated user cannot create expense without required fields
     */
    public function test_authenticated_user_cannot_create_expense_without_required_fields(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson('/api/expenses', [
                'description' => 'Test expense',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['amount', 'date']);
    }

    /**
     * Test authenticated user cannot create expense with negative amount
     */
    public function test_authenticated_user_cannot_create_expense_with_negative_amount(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson('/api/expenses', [
                'amount' => -50.00,
                'date' => '2025-10-29',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['amount']);
    }

    /**
     * Test authenticated user can view their own expense
     */
    public function test_authenticated_user_can_view_own_expense(): void
    {
        $expense = Expense::factory()->create(['user_id' => $this->user->id]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->getJson("/api/expenses/{$expense->id}");

        $response->assertStatus(200)
            ->assertJson([
                'id' => $expense->id,
                'user_id' => $this->user->id,
            ])
            ->assertJsonStructure([
                'category',
            ]);
    }

    /**
     * Test authenticated user cannot view other user's expense
     */
    public function test_authenticated_user_cannot_view_other_user_expense(): void
    {
        $otherUser = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $otherUser->id]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->getJson("/api/expenses/{$expense->id}");

        $response->assertStatus(403)
            ->assertJson([
                'message' => 'Unauthorized',
            ]);
    }

    /**
     * Test authenticated user can update their own expense
     */
    public function test_authenticated_user_can_update_own_expense(): void
    {
        $expense = Expense::factory()->create([
            'user_id' => $this->user->id,
            'amount' => 50.00,
            'description' => 'Old description',
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->putJson("/api/expenses/{$expense->id}", [
                'amount' => 75.50,
                'description' => 'New description',
                'date' => '2025-10-30',
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'id' => $expense->id,
                'amount' => '75.50',
                'description' => 'New description',
            ]);

        $this->assertDatabaseHas('expenses', [
            'id' => $expense->id,
            'amount' => 75.50,
            'description' => 'New description',
        ]);
    }

    /**
     * Test authenticated user can update expense category
     */
    public function test_authenticated_user_can_update_expense_category(): void
    {
        $category = Category::factory()->create(['user_id' => $this->user->id]);
        $expense = Expense::factory()->create(['user_id' => $this->user->id]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->putJson("/api/expenses/{$expense->id}", [
                'category_id' => $category->id,
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'category_id' => $category->id,
            ]);
    }

    /**
     * Test authenticated user cannot update expense with other user's category
     */
    public function test_authenticated_user_cannot_update_expense_with_other_user_category(): void
    {
        $otherUser = User::factory()->create();
        $category = Category::factory()->create(['user_id' => $otherUser->id]);
        $expense = Expense::factory()->create(['user_id' => $this->user->id]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->putJson("/api/expenses/{$expense->id}", [
                'category_id' => $category->id,
            ]);

        $response->assertStatus(403)
            ->assertJson([
                'message' => 'Invalid category',
            ]);
    }

    /**
     * Test authenticated user cannot update other user's expense
     */
    public function test_authenticated_user_cannot_update_other_user_expense(): void
    {
        $otherUser = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $otherUser->id]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->putJson("/api/expenses/{$expense->id}", [
                'amount' => 999.99,
            ]);

        $response->assertStatus(403)
            ->assertJson([
                'message' => 'Unauthorized',
            ]);
    }

    /**
     * Test authenticated user can delete their own expense
     */
    public function test_authenticated_user_can_delete_own_expense(): void
    {
        $expense = Expense::factory()->create(['user_id' => $this->user->id]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->deleteJson("/api/expenses/{$expense->id}");

        $response->assertStatus(200)
            ->assertJson([
                'message' => 'Expense deleted successfully',
            ]);

        $this->assertDatabaseMissing('expenses', [
            'id' => $expense->id,
        ]);
    }

    /**
     * Test authenticated user cannot delete other user's expense
     */
    public function test_authenticated_user_cannot_delete_other_user_expense(): void
    {
        $otherUser = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $otherUser->id]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->deleteJson("/api/expenses/{$expense->id}");

        $response->assertStatus(403)
            ->assertJson([
                'message' => 'Unauthorized',
            ]);

        $this->assertDatabaseHas('expenses', [
            'id' => $expense->id,
        ]);
    }

    /**
     * Test authenticated user can get expenses summary
     */
    public function test_authenticated_user_can_get_expenses_summary(): void
    {
        $category1 = Category::factory()->create(['user_id' => $this->user->id]);
        $category2 = Category::factory()->create(['user_id' => $this->user->id]);

        Expense::factory()->create([
            'user_id' => $this->user->id,
            'amount' => 100.00,
            'category_id' => $category1->id,
            'date' => now()->subDays(10),
        ]);
        Expense::factory()->create([
            'user_id' => $this->user->id,
            'amount' => 200.00,
            'category_id' => $category1->id,
            'date' => now()->subDays(5),
        ]);
        Expense::factory()->create([
            'user_id' => $this->user->id,
            'amount' => 150.00,
            'category_id' => $category2->id,
            'date' => now()->subDays(20),
        ]);
        Expense::factory()->create([
            'user_id' => $this->user->id,
            'amount' => 50.00,
            'date' => now()->subDays(40), // Outside 30 days
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->getJson('/api/expenses-summary');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'total_expenses',
                'recent_expenses',
                'expenses_by_category' => [
                    '*' => [
                        'category',
                        'total',
                    ],
                ],
            ])
            ->assertJson([
                'total_expenses' => 500.00,
                'recent_expenses' => 450.00, // Last 30 days
            ]);

        $data = $response->json();
        $this->assertCount(2, $data['expenses_by_category']);
    }

    /**
     * Test expenses summary only includes user's own expenses
     */
    public function test_expenses_summary_only_includes_user_own_expenses(): void
    {
        $otherUser = User::factory()->create();
        
        Expense::factory()->create([
            'user_id' => $this->user->id,
            'amount' => 100.00,
        ]);
        Expense::factory()->create([
            'user_id' => $otherUser->id,
            'amount' => 500.00,
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->getJson('/api/expenses-summary');

        $response->assertStatus(200)
            ->assertJson([
                'total_expenses' => 100.00,
            ]);
    }

    /**
     * Test unauthenticated user cannot create expense
     */
    public function test_unauthenticated_user_cannot_create_expense(): void
    {
        $response = $this->postJson('/api/expenses', [
            'amount' => 50.00,
            'date' => '2025-10-29',
        ]);

        $response->assertStatus(401);
    }

    /**
     * Test unauthenticated user cannot get expenses summary
     */
    public function test_unauthenticated_user_cannot_get_expenses_summary(): void
    {
        $response = $this->getJson('/api/expenses-summary');

        $response->assertStatus(401);
    }
}

