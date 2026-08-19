<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ArticleController;
use App\Http\Controllers\DeviceController;
use App\Http\Controllers\FeedController;
use App\Http\Controllers\UserFeedController;
use App\Models\Feed;

// APIで使う時のルーティング処理

Route::resource('devices', DeviceController::class);  // デバイスのルーティング
Route::resource('userFeeds', UserFeedController::class);  // ユーザーフィードのルーティング
Route::resource('articles', ArticleController::class);  // Articleのルーティング
Route::resource('feeds', FeedController::class);  // 検索用Feedのルーティング

// 記事のPUT送信は、以下のパスでルーティング
Route::put('/articles/{feedId}/{id}', [ArticleController::class, 'update']);

