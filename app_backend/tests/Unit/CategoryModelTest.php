<?php

namespace Tests\Unit;

use App\Models\Category;
use App\Models\Expense;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CategoryModelTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test category belongs to user relationship
     */
    public function test_category_belongs_to_user(): void
    {
        $user = User::factory()->create();
        $category = Category::factory()->create(['user_id' => $user->id]);

        $this->assertInstanceOf(User::class, $category->user);
        $this->assertEquals($user->id, $category->user->id);
    }

    /**
     * Test category has many expenses relationship
     */
    public function test_category_has_many_expenses(): void
    {
        $user = User::factory()->create();
        $category = Category::factory()->create(['user_id' => $user->id]);
        
        Expense::factory()->count(3)->create([
            'user_id' => $user->id,
            'category_id' => $category->id,
        ]);

        $this->assertCount(3, $category->expenses);
        $this->assertInstanceOf(Expense::class, $category->expenses->first());
    }

    /**
     * Test category can have no expenses
     */
    public function test_category_can_have_no_expenses(): void
    {
        $user = User::factory()->create();
        $category = Category::factory()->create(['user_id' => $user->id]);

        $this->assertCount(0, $category->expenses);
    }
}

