<?php

namespace spec\PhpSpec\Util;

use PhpSpec\Exception\Example\SkippingException;
use PhpSpec\ObjectBehavior;
use Prophecy\Argument;

class MethodAnalyserSpec extends ObjectBehavior
{
    function it_identifies_empty_methods_as_empty()
    {
        $this->methodIsEmpty('spec\PhpSpec\Util\ExampleObject', 'emptyMethod')->shouldReturn(true);
        $this->methodIsEmpty('spec\PhpSpec\Util\ExampleObject', 'emptyMethod2')->shouldReturn(true);
    }

    function it_identifies_commented_methods_as_empty()
    {
        $this->methodIsEmpty('spec\PhpSpec\Util\ExampleObject', 'commentedMethod')->shouldReturn(true);
    }

    function it_identifies_methods_with_code_as_not_empty()
    {
        $this->methodIsEmpty('spec\PhpSpec\Util\ExampleObject', 'nonEmptyMethod')->shouldReturn(false);
    }

    function it_identifies_methods_without_standard_braces_as_non_empty()
    {
        $this->methodIsEmpty('spec\PhpSpec\Util\ExampleObject', 'nonEmptyOneLineMethod')->shouldReturn(false);
        $this->methodIsEmpty('spec\PhpSpec\Util\ExampleObject', 'nonEmptyOneLineMethod2')->shouldReturn(false);
        $this->methodIsEmpty('spec\PhpSpec\Util\ExampleObject', 'nonEmptyOneLineMethod3')->shouldReturn(false);
        $this->methodIsEmpty('spec\PhpSpec\Util\ExampleObject', 'nonEmptyMethod2')->shouldReturn(false);
    }

    function it_identifies_internal_classes_as_non_empty()
    {
        $this->methodIsEmpty('DateTimeZone', 'getOffset')->shouldReturn(false);
    }

    function it_identifies_methods_from_traits()
    {
        if (version_compare(PHP_VERSION, '5.4.0', '<')) {
            throw new SkippingException('Traits implemented since PHP 5.4');
        }

        $this->methodIsEmpty('spec\PhpSpec\Util\ExampleObjectUsingTrait', 'emptyMethodInTrait')->shouldReturn(true);
        $this->methodIsEmpty('spec\PhpSpec\Util\ExampleObjectUsingTrait', 'nonEmptyMethodInTrait')->shouldReturn(false);
    }

    function it_finds_the_real_declaring_class_of_a_method()
    {
        if (version_compare(PHP_VERSION, '5.4.0', '<')) {
            throw new SkippingException('Traits implemented since PHP 5.4');
        }

        $this->getMethodOwnerName('spec\PhpSpec\Util\ExampleObjectUsingTrait', 'emptyMethodInTrait')
            ->shouldReturn('spec\PhpSpec\Util\ExampleTrait');
    }
}

class ExampleObject
{
    public function emptyMethod() {}

    public function emptyMethod2()
    {}

    public function commentedMethod()
    {
        /**
         * this is a comment
         */

        // This is a comment

        /* this is a comment {} */
    }

    public function nonEmptyMethod()
    {
        /**
         * a comment to fool us
         */
        $variable = true;
        // another comment
    }

    public function nonEmptyMethod2() { return 'foo';
    }

    public function nonEmptyOneLineMethod() { return 'foo'; }

    public function nonEmptyOneLineMethod2()
    { return 'foo'; }

    public function nonEmptyOneLineMethod3() {
        return 'foo';
    }
}
