<?php

namespace Tests\Unit;

use App\Models\Category;
use App\Models\Expense;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ExpenseModelTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test expense belongs to user relationship
     */
    public function test_expense_belongs_to_user(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $user->id]);

        $this->assertInstanceOf(User::class, $expense->user);
        $this->assertEquals($user->id, $expense->user->id);
    }

    /**
     * Test expense belongs to category relationship
     */
    public function test_expense_belongs_to_category(): void
    {
        $user = User::factory()->create();
        $category = Category::factory()->create(['user_id' => $user->id]);
        $expense = Expense::factory()->create([
            'user_id' => $user->id,
            'category_id' => $category->id,
        ]);

        $this->assertInstanceOf(Category::class, $expense->category);
        $this->assertEquals($category->id, $expense->category->id);
    }

    /**
     * Test expense can exist without category
     */
    public function test_expense_can_exist_without_category(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create([
            'user_id' => $user->id,
            'category_id' => null,
        ]);

        $this->assertNull($expense->category);
    }
}

