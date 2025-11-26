<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CategoryTest extends TestCase
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
     * Test authenticated user can list their categories
     */
    public function test_authenticated_user_can_list_categories(): void
    {
        Category::factory()->count(3)->create(['user_id' => $this->user->id]);
        Category::factory()->count(2)->create(); // Other user's categories

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->getJson('/api/categories');

        $response->assertStatus(200)
            ->assertJsonCount(3)
            ->assertJsonStructure([
                '*' => [
                    'id',
                    'name',
                    'icon',
                    'color',
                    'user_id',
                    'created_at',
                    'updated_at',
                ],
            ]);
    }

    /**
     * Test unauthenticated user cannot list categories
     */
    public function test_unauthenticated_user_cannot_list_categories(): void
    {
        $response = $this->getJson('/api/categories');

        $response->assertStatus(401);
    }

    /**
     * Test authenticated user can create a category
     */
    public function test_authenticated_user_can_create_category(): void
    {
        $categoryData = [
            'name' => 'Alimentación',
            'icon' => '🍔',
            'color' => '#10B981',
        ];

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson('/api/categories', $categoryData);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'id',
                'name',
                'icon',
                'color',
                'user_id',
                'created_at',
                'updated_at',
            ])
            ->assertJson([
                'name' => 'Alimentación',
                'icon' => '🍔',
                'color' => '#10B981',
                'user_id' => $this->user->id,
            ]);

        $this->assertDatabaseHas('categories', [
            'name' => 'Alimentación',
            'user_id' => $this->user->id,
        ]);
    }

    /**
     * Test authenticated user cannot create category without name
     */
    public function test_authenticated_user_cannot_create_category_without_name(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson('/api/categories', [
                'icon' => '🍔',
                'color' => '#10B981',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['name']);
    }

    /**
     * Test authenticated user can create category with only name
     */
    public function test_authenticated_user_can_create_category_with_only_name(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson('/api/categories', [
                'name' => 'Transporte',
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'name' => 'Transporte',
            ]);
    }

    /**
     * Test authenticated user can view their own category
     */
    public function test_authenticated_user_can_view_own_category(): void
    {
        $category = Category::factory()->create(['user_id' => $this->user->id]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->getJson("/api/categories/{$category->id}");

        $response->assertStatus(200)
            ->assertJson([
                'id' => $category->id,
                'name' => $category->name,
                'user_id' => $this->user->id,
            ]);
    }

    /**
     * Test authenticated user cannot view other user's category
     */
    public function test_authenticated_user_cannot_view_other_user_category(): void
    {
        $otherUser = User::factory()->create();
        $category = Category::factory()->create(['user_id' => $otherUser->id]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->getJson("/api/categories/{$category->id}");

        $response->assertStatus(403)
            ->assertJson([
                'message' => 'Unauthorized',
            ]);
    }

    /**
     * Test authenticated user can update their own category
     */
    public function test_authenticated_user_can_update_own_category(): void
    {
        $category = Category::factory()->create([
            'user_id' => $this->user->id,
            'name' => 'Old Name',
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->putJson("/api/categories/{$category->id}", [
                'name' => 'New Name',
                'icon' => '🚗',
                'color' => '#3B82F6',
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'id' => $category->id,
                'name' => 'New Name',
                'icon' => '🚗',
                'color' => '#3B82F6',
            ]);

        $this->assertDatabaseHas('categories', [
            'id' => $category->id,
            'name' => 'New Name',
        ]);
    }

    /**
     * Test authenticated user can partially update their category
     */
    public function test_authenticated_user_can_partially_update_category(): void
    {
        $category = Category::factory()->create([
            'user_id' => $this->user->id,
            'name' => 'Old Name',
            'icon' => '🍔',
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->putJson("/api/categories/{$category->id}", [
                'name' => 'New Name',
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'name' => 'New Name',
            ]);

        $this->assertDatabaseHas('categories', [
            'id' => $category->id,
            'name' => 'New Name',
            'icon' => '🍔', // Should remain unchanged
        ]);
    }

    /**
     * Test authenticated user cannot update other user's category
     */
    public function test_authenticated_user_cannot_update_other_user_category(): void
    {
        $otherUser = User::factory()->create();
        $category = Category::factory()->create(['user_id' => $otherUser->id]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->putJson("/api/categories/{$category->id}", [
                'name' => 'Hacked Name',
            ]);

        $response->assertStatus(403)
            ->assertJson([
                'message' => 'Unauthorized',
            ]);
    }

    /**
     * Test authenticated user can delete their own category
     */
    public function test_authenticated_user_can_delete_own_category(): void
    {
        $category = Category::factory()->create(['user_id' => $this->user->id]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->deleteJson("/api/categories/{$category->id}");

        $response->assertStatus(200)
            ->assertJson([
                'message' => 'Category deleted successfully',
            ]);

        $this->assertDatabaseMissing('categories', [
            'id' => $category->id,
        ]);
    }

    /**
     * Test authenticated user cannot delete other user's category
     */
    public function test_authenticated_user_cannot_delete_other_user_category(): void
    {
        $otherUser = User::factory()->create();
        $category = Category::factory()->create(['user_id' => $otherUser->id]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->deleteJson("/api/categories/{$category->id}");

        $response->assertStatus(403)
            ->assertJson([
                'message' => 'Unauthorized',
            ]);

        $this->assertDatabaseHas('categories', [
            'id' => $category->id,
        ]);
    }

    /**
     * Test unauthenticated user cannot create category
     */
    public function test_unauthenticated_user_cannot_create_category(): void
    {
        $response = $this->postJson('/api/categories', [
            'name' => 'Test Category',
        ]);

        $response->assertStatus(401);
    }
}

