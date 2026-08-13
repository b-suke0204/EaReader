<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Services\UserFeedService;

class UserFeedController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(UserFeedService $userFeedService)
    {
        // ユーザーのFeed全件取得
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request, UserFeedService $userFeedService)
    {
        // UserFeed保存
        return $userFeedService->createUserFeed($request->except('id'));
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id, UserFeedService $userFeedService)
    {
        // UserFeed取得
        return $userFeedService->getUserFeed($id);
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(string $id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, UserFeedService $userFeedService)
    {
        // UserFeed更新
        return $userFeedService->updateUserFeed($request->all(), $request->device_id);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Request $request, UserFeedService $userFeedService)
    {
        // UserFeed削除
        return $userFeedService->deleteUserFeed($request->device_id);
    }
}
