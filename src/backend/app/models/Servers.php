<?php

namespace MyApp\Models;

use Phalcon\Mvc\Model;
use Phalcon\Messages\Message;
use Phalcon\Filter\Validation;
use Phalcon\Validation\Validator\Uniqueness;
use Phalcon\Validation\Validator\InclusionIn;

class Servers extends Model
{
    public function validation()
    {
        $validator = new Validation();
     

        if ($this->validationHasFailed() === true) {
            return false;
        }
    }
}