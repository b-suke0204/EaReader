<?php
namespace App\Services;

use App\Models\Article;

// Articleのサービスのクラス
class ArticleService {

    // 記事データを取得
    public function getArticles(string $feedId) {
        $articles = Article::where('feed_id', $feedId)->get();
        return response()->json($articles);
    }

    // 記事データ追加
    public function createArticle(array $data) {
        $newArticle = new Article();
        $newArticle->fill($data);
        $newArticle->save();
        return response()->json($newArticle);
    }

    // 記事データ更新
    public function updateArticle(int $feedId, string $id, array $data) {
        return Article::updateOrCreate(['feed_id' => $feedId, 'id' => $id], $data);
    }

    // 記事データ削除
    public function deleteArticles(string $feedId) {
        $articles = Article::where('feed_id', $feedId);
        $articles->delete();
        return response()->json([
            'id' => (int) $feedId
        ]);
    }

}



?>