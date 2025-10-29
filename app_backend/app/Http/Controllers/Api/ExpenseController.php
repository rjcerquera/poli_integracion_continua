<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Expense;
use Illuminate\Http\Request;

class ExpenseController extends Controller
{
    /**
     * @OA\Get(
     *     path="/expenses",
     *     tags={"Expenses"},
     *     summary="Get all user expenses",
     *     security={{"sanctum":{}}},
     *     @OA\Response(
     *         response=200,
     *         description="Expenses retrieved successfully",
     *         @OA\JsonContent(
     *             type="array",
     *             @OA\Items(ref="#/components/schemas/Expense")
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated")
     * )
     */
    public function index(Request $request)
    {
        $expenses = $request->user()
            ->expenses()
            ->with('category')
            ->orderBy('date', 'desc')
            ->get();
        
        return response()->json($expenses);
    }

    /**
     * @OA\Post(
     *     path="/expenses",
     *     tags={"Expenses"},
     *     summary="Create a new expense",
     *     security={{"sanctum":{}}},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"amount","date"},
     *             @OA\Property(property="amount", type="number", format="float", example=50.99),
     *             @OA\Property(property="description", type="string", example="Compra en supermercado"),
     *             @OA\Property(property="date", type="string", format="date", example="2025-10-29"),
     *             @OA\Property(property="category_id", type="integer", example=1)
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="Expense created successfully",
     *         @OA\JsonContent(ref="#/components/schemas/Expense")
     *     )
     * )
     */
    public function store(Request $request)
    {
        $request->validate([
            'amount' => 'required|numeric|min:0',
            'description' => 'nullable|string|max:255',
            'date' => 'required|date',
            'category_id' => 'nullable|exists:categories,id',
        ]);

        // Verify category belongs to user if provided
        if ($request->has('category_id') && $request->category_id) {
            $category = $request->user()->categories()->find($request->category_id);
            
            if (!$category) {
                return response()->json(['message' => 'Invalid category'], 403);
            }
        }

        $expense = $request->user()->expenses()->create($request->all());
        $expense->load('category');

        return response()->json($expense, 201);
    }

    /**
     * Display the specified expense.
     */
    public function show(Request $request, Expense $expense)
    {
        // Check if expense belongs to user
        if ($expense->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $expense->load('category');
        
        return response()->json($expense);
    }

    /**
     * @OA\Put(
     *     path="/expenses/{id}",
     *     tags={"Expenses"},
     *     summary="Update an expense",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             @OA\Property(property="amount", type="number", format="float", example=75.50),
     *             @OA\Property(property="description", type="string", example="Cena en restaurante"),
     *             @OA\Property(property="date", type="string", format="date", example="2025-10-30"),
     *             @OA\Property(property="category_id", type="integer", example=2)
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Expense updated successfully",
     *         @OA\JsonContent(ref="#/components/schemas/Expense")
     *     ),
     *     @OA\Response(response=403, description="Unauthorized")
     * )
     */
    public function update(Request $request, Expense $expense)
    {
        // Check if expense belongs to user
        if ($expense->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $request->validate([
            'amount' => 'sometimes|required|numeric|min:0',
            'description' => 'nullable|string|max:255',
            'date' => 'sometimes|required|date',
            'category_id' => 'nullable|exists:categories,id',
        ]);

        // If updating category, verify it belongs to user
        if ($request->has('category_id') && $request->category_id) {
            $category = $request->user()->categories()->find($request->category_id);
            
            if (!$category) {
                return response()->json(['message' => 'Invalid category'], 403);
            }
        }

        $expense->update($request->all());
        $expense->load('category');

        return response()->json($expense);
    }

    /**
     * @OA\Delete(
     *     path="/expenses/{id}",
     *     tags={"Expenses"},
     *     summary="Delete an expense",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Expense deleted successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Expense deleted successfully")
     *         )
     *     ),
     *     @OA\Response(response=403, description="Unauthorized")
     * )
     */
    public function destroy(Request $request, Expense $expense)
    {
        // Check if expense belongs to user
        if ($expense->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $expense->delete();

        return response()->json(['message' => 'Expense deleted successfully']);
    }

    /**
     * @OA\Get(
     *     path="/expenses-summary",
     *     tags={"Expenses"},
     *     summary="Get expenses summary and statistics",
     *     security={{"sanctum":{}}},
     *     @OA\Response(
     *         response=200,
     *         description="Summary retrieved successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="total_expenses", type="number", format="float", example=1250.50),
     *             @OA\Property(property="recent_expenses", type="number", format="float", example=350.00),
     *             @OA\Property(
     *                 property="expenses_by_category",
     *                 type="array",
     *                 @OA\Items(
     *                     type="object",
     *                     @OA\Property(property="category", ref="#/components/schemas/Category"),
     *                     @OA\Property(property="total", type="number", format="float", example=450.75)
     *                 )
     *             )
     *         )
     *     )
     * )
     */
    public function summary(Request $request)
    {
        $user = $request->user();
        
        // Total expenses
        $totalExpenses = $user->expenses()->sum('amount');
        
        // Expenses by category
        $expensesByCategory = $user->expenses()
            ->selectRaw('category_id, SUM(amount) as total')
            ->with('category:id,name,icon,color')
            ->groupBy('category_id')
            ->whereNotNull('category_id')
            ->get()
            ->map(function ($expense) {
                return [
                    'category' => $expense->category,
                    'total' => $expense->total,
                ];
            });
        
        // Recent expenses (last 30 days)
        $recentExpenses = $user->expenses()
            ->where('date', '>=', now()->subDays(30))
            ->sum('amount');
        
        return response()->json([
            'total_expenses' => $totalExpenses,
            'recent_expenses' => $recentExpenses,
            'expenses_by_category' => $expensesByCategory,
        ]);
    }
}

