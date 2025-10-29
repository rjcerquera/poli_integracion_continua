<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\User;
use Illuminate\Database\Seeder;

class CategorySeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Get the first user (for testing purposes)
        $user = User::first();
        
        if (!$user) {
            $this->command->info('No users found. Please create a user first.');
            return;
        }

        $defaultCategories = [
            ['name' => 'Alimentación', 'icon' => '🍔', 'color' => '#10B981'],
            ['name' => 'Transporte', 'icon' => '🚗', 'color' => '#3B82F6'],
            ['name' => 'Vivienda', 'icon' => '🏠', 'color' => '#8B5CF6'],
            ['name' => 'Servicios', 'icon' => '💡', 'color' => '#F59E0B'],
            ['name' => 'Entretenimiento', 'icon' => '🎮', 'color' => '#EF4444'],
            ['name' => 'Salud', 'icon' => '⚕️', 'color' => '#EC4899'],
            ['name' => 'Educación', 'icon' => '📚', 'color' => '#6366F1'],
            ['name' => 'Ropa', 'icon' => '👕', 'color' => '#14B8A6'],
            ['name' => 'Otros', 'icon' => '📦', 'color' => '#6B7280'],
        ];

        foreach ($defaultCategories as $category) {
            Category::create([
                'name' => $category['name'],
                'icon' => $category['icon'],
                'color' => $category['color'],
                'user_id' => $user->id,
            ]);
        }

        $this->command->info('Default categories created successfully!');
    }
}

