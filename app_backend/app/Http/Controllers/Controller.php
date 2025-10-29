<?php

namespace App\Http\Controllers;

/**
 * @OA\Info(
 *     title="Expense Manager API",
 *     version="1.0.0",
 *     description="API para gestión de gastos personales",
 *     @OA\Contact(
 *         email="support@expensemanager.com"
 *     )
 * )
 * 
 * @OA\Server(
 *     url="http://localhost:8080/api",
 *     description="Development Server"
 * )
 * 
 * @OA\SecurityScheme(
 *     securityScheme="sanctum",
 *     type="http",
 *     scheme="bearer",
 *     bearerFormat="JWT",
 *     description="Laravel Sanctum Token Authentication"
 * )
 */
abstract class Controller
{
    //
}
