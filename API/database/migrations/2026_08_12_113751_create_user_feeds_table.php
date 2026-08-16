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
        Schema::create('user_feeds', function (Blueprint $table) {
            $table->id();
            $table->uuid('device_id')->unique();
            $table->string('feed_title');
            $table->string('link');
            $table->string('summary')->nullable();
            $table->string('icon_url')->nullable();
            $table->string('source')->nullable();
            $table->timestamp('last_updated_at');
            $table->timestamps();
            $table->softDeletes();  // 論理削除を許可
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('user_feeds');
    }
};
