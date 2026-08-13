<?php
namespace App\Services;

use App\Models\UserFeed;
use Illuminate\Http\Request;

// UserFeedのサービスのクラス
class UserFeedService {

    // ユーザーフィードデータをdeviceIdで取得
    public function getUserFeed(string $deviceId) {
        $userFeed = UserFeed::where('device_id', $deviceId)->get();
        return response()->json($userFeed);
    }

    // UserFeedを追加する
    public function createUserFeed(array $data) {
        $newUserFeed = new UserFeed();
        $newUserFeed->fill($data);
        $newUserFeed->save();
        return response()->json($newUserFeed);
    }

    // ユーザーフィード更新
    public function updateUserFeed(array $data, string $deviceId) {
        $userFeed = UserFeed::where('device_id', $deviceId)->first();
        if ($userFeed) {
            $userFeed->fill($data);
            $userFeed->save();
            return response()->json($userFeed);
        } else {
            // ユーザーフィードがなかった場合
            return response()->json(['message' => '該当のユーザーフィードがありませんでした'], 404);
        }
    }

    // ユーザーフィード削除
    public function deleteUserFeed(string $deviceId) {
        $userFeed = UserFeed::where('device_id', $deviceId)->first();  // 念の為、DBからIDを取得して確認
        if ($userFeed) {
            $userFeed->delete();  // softDeletesなので、論理削除
            return response()->json(['message' => 'ユーザーフィードを削除しました'], 200);
        } else {
            return response()->json(['message' => '該当のユーザーフィードがありませんでした'], 404);
        }
    }

}

?>