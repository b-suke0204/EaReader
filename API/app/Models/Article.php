<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class Article extends Model
{
    use HasUuids;  // uuidを使用
    
    protected $keyType = 'string';  // キーの型を指定

    public $incrementing = false;

    protected $fillable = [
        'id',
        'feed_id',
        'article_title',
        'article_link',
        'summary',
        'guid',
        'is_read',
        'is_favorite',
        'is_hidden',
        'thumbnail_url',
        'published_at',
        'content_updated_at',
        'fetchd_at',
    ];

    protected $casts = [
        'is_read' => 'boolean',
        'is_favorite' => 'boolean',
        'is_hidden' => 'boolean',
        'published_at' => 'datetime',
        'content_updated_at' => 'datetime',
        'fetchd_at' => 'datetime',
    ];
}
