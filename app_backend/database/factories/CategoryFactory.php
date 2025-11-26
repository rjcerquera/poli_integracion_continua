<?php

namespace Database\Factories;

use App\Models\Category;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Category>
 */
class CategoryFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'name' => fake()->words(2, true),
            'icon' => fake()->randomElement(['🍔', '🚗', '🏠', '💊', '🎮', '📱', '👕', '🍕']),
            'color' => fake()->hexColor(),
            'user_id' => User::factory(),
        ];
    }
}

