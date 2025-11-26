<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Ejecutar las migraciones.
     */
    public function up(): void
    {
        Schema::table('expenses', function (Blueprint $table) {
            // Primero eliminar la foreign key
            $table->dropForeign(['category_id']);
            
            // Modificar las columnas para hacerlas nullable
            $table->string('description')->nullable()->change();
            $table->unsignedBigInteger('category_id')->nullable()->change();
            
            // Recrear la foreign key con onDelete('set null')
            $table->foreign('category_id')
                ->references('id')
                ->on('categories')
                ->onDelete('set null');
        });
    }

    /**
     * Revertir las migraciones.
     */
    public function down(): void
    {
        Schema::table('expenses', function (Blueprint $table) {
            // Eliminar la foreign key actual
            $table->dropForeign(['category_id']);
            
            // Restaurar las columnas a no nullable
            $table->string('description')->nullable(false)->change();
            $table->unsignedBigInteger('category_id')->nullable(false)->change();
            
            // Recrear la foreign key original con onDelete('cascade')
            $table->foreign('category_id')
                ->references('id')
                ->on('categories')
                ->onDelete('cascade');
        });
    }
};

