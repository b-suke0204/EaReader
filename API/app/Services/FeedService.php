<?php
namespace App\Services;

use App\Models\Feed;

// 検索用Feed関連のサービスクラス
class FeedService {

    public function saveFeed(array $data, $feedURL) {
        $newFeed = Feed::firstOrCreate(['feed_url' => $feedURL], $data);
        // $newFeed = new Feed();
        // $newFeed->fill($data);
        // $newFeed->save();
        return response()->json($newFeed);  // 一応返しておく
    }

}

?>