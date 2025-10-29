<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * @OA\Schema(
 *     schema="Expense",
 *     type="object",
 *     @OA\Property(property="id", type="integer", example=1),
 *     @OA\Property(property="amount", type="number", format="float", example=50.99),
 *     @OA\Property(property="description", type="string", example="Compra en supermercado"),
 *     @OA\Property(property="date", type="string", format="date", example="2025-10-29"),
 *     @OA\Property(property="category_id", type="integer", example=1),
 *     @OA\Property(property="category", ref="#/components/schemas/Category"),
 *     @OA\Property(property="user_id", type="integer", example=1),
 *     @OA\Property(property="created_at", type="string", format="date-time"),
 *     @OA\Property(property="updated_at", type="string", format="date-time")
 * )
 */
class Expense extends Model
{
    use HasFactory;

    protected $fillable = [
        'amount',
        'description',
        'date',
        'category_id',
        'user_id',
    ];

    protected $casts = [
        'date' => 'date',
        'amount' => 'decimal:2',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }
}

