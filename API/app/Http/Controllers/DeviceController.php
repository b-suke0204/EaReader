<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Services\DeviceService;

class DeviceController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        // デバイスデータ全件取得
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
    public function store(Request $request, DeviceService $deviceService)
    {
        // デバイスデータ作成
        return $deviceService->createDevice($request->only([
            'device_id',
            'last_seen_at',
            'latest_updated_at',
            'article_display_count',
        ]));
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id, DeviceService $deviceService)
    {
        // id検索して取得
        return $deviceService->getDevice($id);
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
    public function update(Request $request, DeviceService $deviceService)
    {
        // デバイスデータ更新
        return $deviceService->updateDevice($request->all(), $request->device_id);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        // デバイスデータ削除 (レコードごと)
    }
}
