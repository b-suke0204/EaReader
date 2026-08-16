<?php
namespace APp\Services;

use App\Models\Device;

// デバイスモデルのサービスのクラス
class DeviceService {

    // デバイス取得
    public function getDevice(string $deviceId) {
        // deviceIdで検索する
        $device = Device::where('device_id', $deviceId)->first();
        return response()->json($device);
    }

    // デバイス追加
    public function createDevice(array $data) {
        $newDevice = new Device();
        $newDevice->fill($data);
        $newDevice->save();
        return response()->json($newDevice);
    }

    // デバイス更新
    public function updateDevice(array $data, string $deviceId) {
        // $device = Device::findOrFail(['device_id' => $deviceId]);
        $device = Device::where('device_id', $deviceId)->firstOrFail();
        if ($device) {
            $device->fill($data);
            $device->save();
            return response()->json($device);
        } else {
            // 明示的にエラーメッセージを送りたいので、ifで条件分岐した
            return response()->json(['message' => 'デバイスがありませんでした'], 404);
        }
    }

}


?>