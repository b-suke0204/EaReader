<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{

    /**
     * Run the migrations.
     */
    public function up(): void
    {

        Schema::create('articles', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->integer('feed_id');
            $table->string('article_title');
            $table->string('article_link')->nullable();
            $table->string('summary')->nullable();
            $table->string('guid')->nullable();
            $table->boolean('is_read')->default(false);
            $table->boolean('is_favorite')->default(false);
            $table->boolean('is_hidden')->default(false);
            $table->string('thumbnail_url')->nullable();
            $table->timestamp('published_at')->nullable();
            $table->timestamp('content_updated_at')->nullable();
            $table->timestamp('fetched_at')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('articles');
    }
};
