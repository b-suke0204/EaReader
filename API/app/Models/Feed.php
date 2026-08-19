<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Feed extends Model
{
    protected $fillable = [
        'feed_url',
        'title',
        'site_url',
        'summary',
        'icon_url',
        'source',
    ];

    
}
