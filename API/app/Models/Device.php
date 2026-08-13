<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Device extends Model
{
    
    protected $fillable = [
        'device_id',
        'last_seen_at',
        'latest_updated_at',
        'article_display_count'
    ];

    protected $casts = [
        'last_seen_at' => 'datetime',
        'latest_updated_at' => 'datetime',
    ];

}
