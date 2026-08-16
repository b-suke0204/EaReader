<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class UserFeed extends Model
{
    use SoftDeletes;
    
    protected $fillable = [
        'device_id',
        'feed_title',
        'link',
        'summary',
        'icon_url',
        'source',
        'last_updated_at'
    ];

    protected $casts = [
        'last_updated_at' => 'datetime',
    ];

}
