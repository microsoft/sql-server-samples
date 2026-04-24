<?php
/**
 * Mockery
 *
 * LICENSE
 *
 * This source file is subject to the new BSD license that is bundled
 * with this package in the file LICENSE.txt.
 * It is also available through the world-wide-web at this URL:
 * http://github.com/padraic/mockery/master/LICENSE
 * If you did not receive a copy of the license and are unable to
 * obtain it through the world-wide-web, please send an email
 * to padraic@php.net so we can send you a copy immediately.
 *
 * @category   Mockery
 * @package    Mockery
 * @subpackage UnitTests
 * @copyright  Copyright (c) 2010-2014 Pádraic Brady (http://blog.astrumfutura.com)
 * @license    http://github.com/padraic/mockery/blob/master/LICENSE New BSD License
 */

use Mockery\Adapter\Phpunit\MockeryTestCase;

class ExpectationTest extends MockeryTestCase
{

    public function setup()
    {
        $this->container = new \Mockery\Container(\Mockery::getDefaultGenerator(), \Mockery::getDefaultLoader());
        $this->mock = $this->container->mock('foo');
    }

    public function teardown()
    {
        \Mockery::getConfiguration()->allowMockingNonExistentMethods(true);
        $this->container->mockery_close();
    }

    public function testReturnsNullWhenNoArgs()
    {
        $this->mock->shouldReceive('foo');
        $this->assertNull($this->mock->foo());
    }

    public function testReturnsNullWhenSingleArg()
    {
        $this->mock->shouldReceive('foo');
        $this->assertNull($this->mock->foo(1));
    }

    public function testReturnsNullWhenManyArgs()
    {
        $this->mock->shouldReceive('foo');
        $this->assertNull($this->mock->foo('foo', array(), new stdClass));
    }

    public function testReturnsNullIfNullIsReturnValue()
    {
        $this->mock->shouldReceive('foo')->andReturn(null);
        $this->assertNull($this->mock->foo());
    }

    public function testReturnsNullForMockedExistingClassIfAndreturnnullCalled()
    {
        $mock = $this->container->mock('MockeryTest_Foo');
        $mock->shouldReceive('foo')->andReturn(null);
        $this->assertNull($mock->foo());
    }

    public function testReturnsNullForMockedExistingClassIfNullIsReturnValue()
    {
        $mock = $this->container->mock('MockeryTest_Foo');
        $mock->shouldReceive('foo')->andReturnNull();
        $this->assertNull($mock->foo());
    }

    public function testReturnsSameValueForAllIfNoArgsExpectationAndNoneGiven()
    {
        $this->mock->shouldReceive('foo')->andReturn(1);
        $this->assertEquals(1, $this->mock->foo());
    }

    public function testSetsPublicPropertyWhenRequested()
    {
        $this->mock->bar = null;
        $this->mock->shouldReceive('foo')->andSet('bar', 'baz');
        $this->assertNull($this->mock->bar);
        $this->mock->foo();
        $this->assertEquals('baz', $this->mock->bar);
    }

    public function testSetsPublicPropertyWhenRequestedUsingAlias()
    {
        $this->mock->bar = null;
        $this->mock->shouldReceive('foo')->set('bar', 'baz');
        $this->assertNull($this->mock->bar);
        $this->mock->foo();
        $this->assertEquals('baz', $this->mock->bar);
    }

    public function testSetsPublicPropertiesWhenRequested()
    {
        $this->mock->bar = null;
        $this->mock->shouldReceive('foo')->andSet('bar', 'baz', 'bazz', 'bazzz');
        $this->assertNull($this->mock->bar);
        $this->mock->foo();
        $this->assertEquals('baz', $this->mock->bar);
        $this->mock->foo();
        $this->assertEquals('bazz', $this->mock->bar);
        $this->mock->foo();
        $this->assertEquals('bazzz', $this->mock->bar);
    }

    public function testSetsPublicPropertiesWhenRequestedUsingAlias()
    {
        $this->mock->bar = null;
        $this->mock->shouldReceive('foo')->set('bar', 'baz', 'bazz', 'bazzz');
        $this->assertAttributeEmpty('bar', $this->mock);
        $this->mock->foo();
        $this->assertEquals('baz', $this->mock->bar);
        $this->mock->foo();
        $this->assertEquals('bazz', $this->mock->bar);
        $this->mock->foo();
        $this->assertEquals('bazzz', $this->mock->bar);
    }

    public function testSetsPublicPropertiesWhenRequestedMoreTimesThanSetValues()
    {
        $this->mock->bar = null;
        $this->mock->shouldReceive('foo')->andSet('bar', 'baz', 'bazz');
        $this->assertNull($this->mock->bar);
        $this->mock->foo();
        $this->assertEquals('baz', $this->mock->bar);
        $this->mock->foo();
        $this->assertEquals('bazz', $this->mock->bar);
        $this->mock->foo();
        $this->assertEquals('bazz', $this->mock->bar);
    }

    public function testSetsPublicPropertiesWhenRequestedMoreTimesThanSetValuesUsingAlias()
    {
        $this->mock->bar = null;
        $this->mock->shouldReceive('foo')->andSet('bar', 'baz', 'bazz');
        $this->assertNull($this->mock->bar);
        $this->mock->foo();
        $this->assertEquals('baz', $this->mock->bar);
        $this->mock->foo();
        $this->assertEquals('bazz', $this->mock->bar);
        $this->mock->foo();
        $this->assertEquals('bazz', $this->mock->bar);
    }

    public function testSetsPublicPropertiesWhenRequestedMoreTimesThanSetValuesWithDirectSet()
    {
        $this->mock->bar = null;
        $this->mock->shouldReceive('foo')->andSet('bar', 'baz', 'bazz');
        $this->assertNull($this->mock->bar);
        $this->mock->foo();
        $this->assertEquals('baz', $this->mock->bar);
        $this->mock->foo();
        $this->assertEquals('bazz', $this->mock->bar);
        $this->mock->bar = null;
        $this->mock->foo();
        $this->assertNull($this->mock->bar);
    }

    public function testSetsPublicPropertiesWhenRequestedMoreTimesThanSetValuesWithDirectSetUsingAlias()
    {
        $this->mock->bar = null;
        $this->mock->shouldReceive('foo')->set('bar', 'baz', 'bazz');
        $this->assertNull($this->mock->bar);
        $this->mock->foo();
        $this->assertEquals('baz', $this->mock->bar);
        $this->mock->foo();
        $this->assertEquals('bazz', $this->mock->bar);
        $this->mock->bar = null;
        $this->mock->foo();
        $this->assertNull($this->mock->bar);
    }

    public function testReturnsSameValueForAllIfNoArgsExpectationAndSomeGiven()
    {
        $this->mock->shouldReceive('foo')->andReturn(1);
        $this->assertEquals(1, $this->mock->foo('foo'));
    }

    public function testReturnsValueFromSequenceSequentially()
    {
        $this->mock->shouldReceive('foo')->andReturn(1, 2, 3);
        $this->mock->foo('foo');
        $this->assertEquals(2, $this->mock->foo('foo'));
    }

    public function testReturnsValueFromSequenceSequentiallyAndRepeatedlyReturnsFinalValueOnExtraCalls()
    {
        $this->mock->shouldReceive('foo')->andReturn(1, 2, 3);
        $this->mock->foo('foo');
        $this->mock->foo('foo');
        $this->assertEquals(3, $this->mock->foo('foo'));
        $this->assertEquals(3, $this->mock->foo('foo'));
    }

    public function testReturnsValueFromSequenceSequentiallyAndRepeatedlyReturnsFinalValueOnExtraCallsWithManyAndReturnCalls()
    {
        $this->mock->shouldReceive('foo')->andReturn(1)->andReturn(2, 3);
        $this->mock->foo('foo');
        $this->mock->foo('foo');
        $this->assertEquals(3, $this->mock->foo('foo'));
        $this->assertEquals(3, $this->mock->foo('foo'));
    }

    public function testReturnsValueOfClosure()
    {
        $this->mock->shouldReceive('foo')->with(5)->andReturnUsing(function ($v) {return $v+1;});
        $this->assertEquals(6, $this->mock->foo(5));
    }

    public function testReturnsUndefined()
    {
        $this->mock->shouldReceive('foo')->andReturnUndefined();
        $this->assertTrue($this->mock->foo() instanceof \Mockery\Undefined);
    }

    public function testReturnsValuesSetAsArray()
    {
        $this->mock->shouldReceive('foo')->andReturnValues(array(1, 2, 3));
        $this->assertEquals(1, $this->mock->foo());
        $this->assertEquals(2, $this->mock->foo());
        $this->assertEquals(3, $this->mock->foo());
    }

    /**
     * @expectedException OutOfBoundsException
     */
    public function testThrowsException()
    {
        $this->mock->shouldReceive('foo')->andThrow(new OutOfBoundsException);
        $this->mock->foo();
    }

    /**
     * @expectedException OutOfBoundsException
     */
    public function testThrowsExceptionBasedOnArgs()
    {
        $this->mock->shouldReceive('foo')->andThrow('OutOfBoundsException');
        $this->mock->foo();
    }

    public function testThrowsExceptionBasedOnArgsWithMessage()
    {
        $this->mock->shouldReceive('foo')->andThrow('OutOfBoundsException', 'foo');
        try {
            $this->mock->foo();
        } catch (OutOfBoundsException $e) {
            $this->assertEquals('foo', $e->getMessage());
        }
    }

    /**
     * @expectedException OutOfBoundsException
     */
    public function testThrowsExceptionSequentially()
    {
        $this->mock->shouldReceive('foo')->andThrow(new Exception)->andThrow(new OutOfBoundsException);
        try {
            $this->mock->foo();
        } catch (Exception $e) {
        }
        $this->mock->foo();
    }

    public function testAndThrowExceptions()
    {
        $this->mock->shouldReceive('foo')->andThrowExceptions(array(
            new OutOfBoundsException,
            new InvalidArgumentException,
        ));

        try {
            $this->mock->foo();
            throw new Exception("Expected OutOfBoundsException, non thrown");
        } catch (\Exception $e) {
            $this->assertInstanceOf("OutOfBoundsException", $e, "Wrong or no exception thrown: {$e->getMessage()}");
        }

        try {
            $this->mock->foo();
            throw new Exception("Expected InvalidArgumentException, non thrown");
        } catch (\Exception $e) {
            $this->assertInstanceOf("InvalidArgumentException", $e, "Wrong or no exception thrown: {$e->getMessage()}");
        }
    }

    /**
     * @expectedException Mockery\Exception
     * @expectedExceptionMessage You must pass an array of exception objects to andThrowExceptions
     */
    public function testAndThrowExceptionsCatchNonExceptionArgument()
    {
        $this->mock
            ->shouldReceive('foo')
            ->andThrowExceptions(array('NotAnException'));
    }

    public function testMultipleExpectationsWithReturns()
    {
        $this->mock->shouldReceive('foo')->with(1)->andReturn(10);
        $this->mock->shouldReceive('bar')->with(2)->andReturn(20);
        $this->assertEquals(10, $this->mock->foo(1));
        $this->assertEquals(20, $this->mock->bar(2));
    }

    public function testExpectsNoArguments()
    {
        $this->mock->shouldReceive('foo')->withNoArgs();
        $this->mock->foo();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testExpectsNoArgumentsThrowsExceptionIfAnyPassed()
    {
        $this->mock->shouldReceive('foo')->withNoArgs();
        $this->mock->foo(1);
    }

    public function testExpectsArgumentsArray()
    {
        $this->mock->shouldReceive('foo')->withArgs(array(1, 2));
        $this->mock->foo(1, 2);
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testExpectsArgumentsArrayThrowsExceptionIfPassedEmptyArray()
    {
        $this->mock->shouldReceive('foo')->withArgs(array());
        $this->mock->foo(1, 2);
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testExpectsArgumentsArrayThrowsExceptionIfNoArgumentsPassed()
    {
        $this->mock->shouldReceive('foo')->with();
        $this->mock->foo(1);
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testExpectsArgumentsArrayThrowsExceptionIfPassedWrongArguments()
    {
        $this->mock->shouldReceive('foo')->withArgs(array(1, 2));
        $this->mock->foo(3, 4);
    }

    /**
     * @expectedException \Mockery\Exception
     * @expectedExceptionMessageRegExp /foo\(NULL\)/
     */
    public function testExpectsStringArgumentExceptionMessageDifferentiatesBetweenNullAndEmptyString()
    {
        $this->mock->shouldReceive('foo')->withArgs(array('a string'));
        $this->mock->foo(null);
    }

    public function testExpectsAnyArguments()
    {
        $this->mock->shouldReceive('foo')->withAnyArgs();
        $this->mock->foo();
        $this->mock->foo(1);
        $this->mock->foo(1, 'k', new stdClass);
    }

    public function testExpectsArgumentMatchingRegularExpression()
    {
        $this->mock->shouldReceive('foo')->with('/bar/i');
        $this->mock->foo('xxBARxx');
    }

    public function testExpectsArgumentMatchingObjectType()
    {
        $this->mock->shouldReceive('foo')->with('\stdClass');
        $this->mock->foo(new stdClass);
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testThrowsExceptionOnNoArgumentMatch()
    {
        $this->mock->shouldReceive('foo')->with(1);
        $this->mock->foo(2);
    }

    public function testNeverCalled()
    {
        $this->mock->shouldReceive('foo')->never();
        $this->container->mockery_verify();
    }

    public function testShouldNotReceive()
    {
        $this->mock->shouldNotReceive('foo');
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception\InvalidCountException
     */
    public function testShouldNotReceiveThrowsExceptionIfMethodCalled()
    {
        $this->mock->shouldNotReceive('foo');
        $this->mock->foo();
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception\InvalidCountException
     */
    public function testShouldNotReceiveWithArgumentThrowsExceptionIfMethodCalled()
    {
        $this->mock->shouldNotReceive('foo')->with(2);
        $this->mock->foo(2);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\CountValidator\Exception
     */
    public function testNeverCalledThrowsExceptionOnCall()
    {
        $this->mock->shouldReceive('foo')->never();
        $this->mock->foo();
        $this->container->mockery_verify();
    }

    public function testCalledOnce()
    {
        $this->mock->shouldReceive('foo')->once();
        $this->mock->foo();
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\CountValidator\Exception
     */
    public function testCalledOnceThrowsExceptionIfNotCalled()
    {
        $this->mock->shouldReceive('foo')->once();
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\CountValidator\Exception
     */
    public function testCalledOnceThrowsExceptionIfCalledTwice()
    {
        $this->mock->shouldReceive('foo')->once();
        $this->mock->foo();
        $this->mock->foo();
        $this->container->mockery_verify();
    }

    public function testCalledTwice()
    {
        $this->mock->shouldReceive('foo')->twice();
        $this->mock->foo();
        $this->mock->foo();
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\CountValidator\Exception
     */
    public function testCalledTwiceThrowsExceptionIfNotCalled()
    {
        $this->mock->shouldReceive('foo')->twice();
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\CountValidator\Exception
     */
    public function testCalledOnceThrowsExceptionIfCalledThreeTimes()
    {
        $this->mock->shouldReceive('foo')->twice();
        $this->mock->foo();
        $this->mock->foo();
        $this->mock->foo();
        $this->container->mockery_verify();
    }

    public function testCalledZeroOrMoreTimesAtZeroCalls()
    {
        $this->mock->shouldReceive('foo')->zeroOrMoreTimes();
        $this->container->mockery_verify();
    }

    public function testCalledZeroOrMoreTimesAtThreeCalls()
    {
        $this->mock->shouldReceive('foo')->zeroOrMoreTimes();
        $this->mock->foo();
        $this->mock->foo();
        $this->mock->foo();
        $this->container->mockery_verify();
    }

    public function testTimesCountCalls()
    {
        $this->mock->shouldReceive('foo')->times(4);
        $this->mock->foo();
        $this->mock->foo();
        $this->mock->foo();
        $this->mock->foo();
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\CountValidator\Exception
     */
    public function testTimesCountCallThrowsExceptionOnTooFewCalls()
    {
        $this->mock->shouldReceive('foo')->times(2);
        $this->mock->foo();
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\CountValidator\Exception
     */
    public function testTimesCountCallThrowsExceptionOnTooManyCalls()
    {
        $this->mock->shouldReceive('foo')->times(2);
        $this->mock->foo();
        $this->mock->foo();
        $this->mock->foo();
        $this->container->mockery_verify();
    }

    public function testCalledAtLeastOnceAtExactlyOneCall()
    {
        $this->mock->shouldReceive('foo')->atLeast()->once();
        $this->mock->foo();
        $this->container->mockery_verify();
    }

    public function testCalledAtLeastOnceAtExactlyThreeCalls()
    {
        $this->mock->shouldReceive('foo')->atLeast()->times(3);
        $this->mock->foo();
        $this->mock->foo();
        $this->mock->foo();
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\CountValidator\Exception
     */
    public function testCalledAtLeastThrowsExceptionOnTooFewCalls()
    {
        $this->mock->shouldReceive('foo')->atLeast()->twice();
        $this->mock->foo();
        $this->container->mockery_verify();
    }

    public function testCalledAtMostOnceAtExactlyOneCall()
    {
        $this->mock->shouldReceive('foo')->atMost()->once();
        $this->mock->foo();
        $this->container->mockery_verify();
    }

    public function testCalledAtMostAtExactlyThreeCalls()
    {
        $this->mock->shouldReceive('foo')->atMost()->times(3);
        $this->mock->foo();
        $this->mock->foo();
        $this->mock->foo();
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\CountValidator\Exception
     */
    public function testCalledAtLeastThrowsExceptionOnTooManyCalls()
    {
        $this->mock->shouldReceive('foo')->atMost()->twice();
        $this->mock->foo();
        $this->mock->foo();
        $this->mock->foo();
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\CountValidator\Exception
     */
    public function testExactCountersOverrideAnyPriorSetNonExactCounters()
    {
        $this->mock->shouldReceive('foo')->atLeast()->once()->once();
        $this->mock->foo();
        $this->mock->foo();
        $this->container->mockery_verify();
    }

    public function testComboOfLeastAndMostCallsWithOneCall()
    {
        $this->mock->shouldReceive('foo')->atleast()->once()->atMost()->twice();
        $this->mock->foo();
        $this->container->mockery_verify();
    }

    public function testComboOfLeastAndMostCallsWithTwoCalls()
    {
        $this->mock->shouldReceive('foo')->atleast()->once()->atMost()->twice();
        $this->mock->foo();
        $this->mock->foo();
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\CountValidator\Exception
     */
    public function testComboOfLeastAndMostCallsThrowsExceptionAtTooFewCalls()
    {
        $this->mock->shouldReceive('foo')->atleast()->once()->atMost()->twice();
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\CountValidator\Exception
     */
    public function testComboOfLeastAndMostCallsThrowsExceptionAtTooManyCalls()
    {
        $this->mock->shouldReceive('foo')->atleast()->once()->atMost()->twice();
        $this->mock->foo();
        $this->mock->foo();
        $this->mock->foo();
        $this->container->mockery_verify();
    }

    public function testCallCountingOnlyAppliesToMatchedExpectations()
    {
        $this->mock->shouldReceive('foo')->with(1)->once();
        $this->mock->shouldReceive('foo')->with(2)->twice();
        $this->mock->shouldReceive('foo')->with(3);
        $this->mock->foo(1);
        $this->mock->foo(2);
        $this->mock->foo(2);
        $this->mock->foo(3);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\CountValidator\Exception
     */
    public function testCallCountingThrowsExceptionOnAnyMismatch()
    {
        $this->mock->shouldReceive('foo')->with(1)->once();
        $this->mock->shouldReceive('foo')->with(2)->twice();
        $this->mock->shouldReceive('foo')->with(3);
        $this->mock->shouldReceive('bar');
        $this->mock->foo(1);
        $this->mock->foo(2);
        $this->mock->foo(3);
        $this->mock->bar();
        $this->container->mockery_verify();
    }

    public function testOrderedCallsWithoutError()
    {
        $this->mock->shouldReceive('foo')->ordered();
        $this->mock->shouldReceive('bar')->ordered();
        $this->mock->foo();
        $this->mock->bar();
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testOrderedCallsWithOutOfOrderError()
    {
        $this->mock->shouldReceive('foo')->ordered();
        $this->mock->shouldReceive('bar')->ordered();
        $this->mock->bar();
        $this->mock->foo();
        $this->container->mockery_verify();
    }

    public function testDifferentArgumentsAndOrderingsPassWithoutException()
    {
        $this->mock->shouldReceive('foo')->with(1)->ordered();
        $this->mock->shouldReceive('foo')->with(2)->ordered();
        $this->mock->foo(1);
        $this->mock->foo(2);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testDifferentArgumentsAndOrderingsThrowExceptionWhenInWrongOrder()
    {
        $this->mock->shouldReceive('foo')->with(1)->ordered();
        $this->mock->shouldReceive('foo')->with(2)->ordered();
        $this->mock->foo(2);
        $this->mock->foo(1);
        $this->container->mockery_verify();
    }

    public function testUnorderedCallsIgnoredForOrdering()
    {
        $this->mock->shouldReceive('foo')->with(1)->ordered();
        $this->mock->shouldReceive('foo')->with(2);
        $this->mock->shouldReceive('foo')->with(3)->ordered();
        $this->mock->foo(2);
        $this->mock->foo(1);
        $this->mock->foo(2);
        $this->mock->foo(3);
        $this->mock->foo(2);
        $this->container->mockery_verify();
    }

    public function testOrderingOfDefaultGrouping()
    {
        $this->mock->shouldReceive('foo')->ordered();
        $this->mock->shouldReceive('bar')->ordered();
        $this->mock->foo();
        $this->mock->bar();
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testOrderingOfDefaultGroupingThrowsExceptionOnWrongOrder()
    {
        $this->mock->shouldReceive('foo')->ordered();
        $this->mock->shouldReceive('bar')->ordered();
        $this->mock->bar();
        $this->mock->foo();
        $this->container->mockery_verify();
    }

    public function testOrderingUsingNumberedGroups()
    {
        $this->mock->shouldReceive('start')->ordered(1);
        $this->mock->shouldReceive('foo')->ordered(2);
        $this->mock->shouldReceive('bar')->ordered(2);
        $this->mock->shouldReceive('final')->ordered();
        $this->mock->start();
        $this->mock->bar();
        $this->mock->foo();
        $this->mock->bar();
        $this->mock->final();
        $this->container->mockery_verify();
    }

    public function testOrderingUsingNamedGroups()
    {
        $this->mock->shouldReceive('start')->ordered('start');
        $this->mock->shouldReceive('foo')->ordered('foobar');
        $this->mock->shouldReceive('bar')->ordered('foobar');
        $this->mock->shouldReceive('final')->ordered();
        $this->mock->start();
        $this->mock->bar();
        $this->mock->foo();
        $this->mock->bar();
        $this->mock->final();
        $this->container->mockery_verify();
    }

    /**
     * @group 2A
     */
    public function testGroupedUngroupedOrderingDoNotOverlap()
    {
        $s = $this->mock->shouldReceive('start')->ordered();
        $m = $this->mock->shouldReceive('mid')->ordered('foobar');
        $e = $this->mock->shouldReceive('end')->ordered();
        $this->assertTrue($s->getOrderNumber() < $m->getOrderNumber());
        $this->assertTrue($m->getOrderNumber() < $e->getOrderNumber());
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testGroupedOrderingThrowsExceptionWhenCallsDisordered()
    {
        $this->mock->shouldReceive('foo')->ordered('first');
        $this->mock->shouldReceive('bar')->ordered('second');
        $this->mock->bar();
        $this->mock->foo();
        $this->container->mockery_verify();
    }

    public function testExpectationMatchingWithNoArgsOrderings()
    {
        $this->mock->shouldReceive('foo')->withNoArgs()->once()->ordered();
        $this->mock->shouldReceive('bar')->withNoArgs()->once()->ordered();
        $this->mock->shouldReceive('foo')->withNoArgs()->once()->ordered();
        $this->mock->foo();
        $this->mock->bar();
        $this->mock->foo();
        $this->container->mockery_verify();
    }

    public function testExpectationMatchingWithAnyArgsOrderings()
    {
        $this->mock->shouldReceive('foo')->withAnyArgs()->once()->ordered();
        $this->mock->shouldReceive('bar')->withAnyArgs()->once()->ordered();
        $this->mock->shouldReceive('foo')->withAnyArgs()->once()->ordered();
        $this->mock->foo();
        $this->mock->bar();
        $this->mock->foo();
        $this->container->mockery_verify();
    }

    public function testEnsuresOrderingIsNotCrossMockByDefault()
    {
        $this->mock->shouldReceive('foo')->ordered();
        $mock2 = $this->container->mock('bar');
        $mock2->shouldReceive('bar')->ordered();
        $mock2->bar();
        $this->mock->foo();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testEnsuresOrderingIsCrossMockWhenGloballyFlagSet()
    {
        $this->mock->shouldReceive('foo')->globally()->ordered();
        $mock2 = $this->container->mock('bar');
        $mock2->shouldReceive('bar')->globally()->ordered();
        $mock2->bar();
        $this->mock->foo();
    }

    public function testExpectationCastToStringFormatting()
    {
        $exp = $this->mock->shouldReceive('foo')->with(1, 'bar', new stdClass, array('Spam' => 'Ham', 'Bar' => 'Baz'));
        $this->assertEquals('[foo(1, "bar", object(stdClass), array(\'Spam\'=>\'Ham\',\'Bar\'=>\'Baz\',))]', (string) $exp);
    }

    public function testLongExpectationCastToStringFormatting()
    {
        $exp = $this->mock->shouldReceive('foo')->with(array('Spam' => 'Ham', 'Bar' => 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'Bar', 'Baz', 'End'));
        $this->assertEquals("[foo(array('Spam'=>'Ham','Bar'=>'Baz',0=>'Bar',1=>'Baz',2=>'Bar',3=>'Baz',4=>'Bar',5=>'Baz',6=>'Bar',7=>'Baz',8=>'Bar',9=>'Baz',10=>'Bar',11=>'Baz',12=>'Bar',13=>'Baz',14=>'Bar',15=>'Baz',16=>'Bar',17=>'Baz',18=>'Bar',19=>'Baz',20=>'Bar',21=>'Baz',22=>'Bar',23=>'Baz',24=>'Bar',25=>'Baz',26=>'Bar',27=>'Baz',28=>'Bar',29=>'Baz',30=>'Bar',31=>'Baz',32=>'Bar',33=>'Baz',34=>'Bar',35=>'Baz',36=>'Bar',37=>'Baz',38=>'Bar',39=>'Baz',40=>'Bar',41=>'Baz',42=>'Bar',43=>'Baz',44=>'Bar',45=>'Baz',46=>'Baz',47=>'Bar',48=>'Baz',49=>'Bar',50=>'Baz',51=>'Bar',52=>'Baz',53=>'Bar',54=>'Baz',55=>'Bar',56=>'Baz',57=>'Baz',58=>'Bar',59=>'Baz',60=>'Bar',61=>'Baz',62=>'Bar',63=>'Baz',64=>'Bar',65=>'Baz',66=>'Bar',67=>'Baz',68=>'Baz',69=>'Bar',70=>'Baz',71=>'Bar',72=>'Baz',73=>'Bar',74=>'Baz',75=>'Bar',76=>'Baz',77=>'Bar',78=>'Baz',79=>'Baz',80=>'Bar',81=>'Baz',82=>'Bar',83=>'Baz',84=>'Bar',85=>'Baz',86=>'Bar',87=>'Baz',88=>'Bar',89=>'Baz',90=>'Baz',91=>'Bar',92=>'Baz',93=>'Bar',94=>'Baz',95=>'Bar',96=>'Baz',97=>'Ba...))]", (string) $exp);
    }

    public function testMultipleExpectationCastToStringFormatting()
    {
        $exp = $this->mock->shouldReceive('foo', 'bar')->with(1);
        $this->assertEquals('[foo(1), bar(1)]', (string) $exp);
    }

    public function testGroupedOrderingWithLimitsAllowsMultipleReturnValues()
    {
        $this->mock->shouldReceive('foo')->with(2)->once()->andReturn('first');
        $this->mock->shouldReceive('foo')->with(2)->twice()->andReturn('second/third');
        $this->mock->shouldReceive('foo')->with(2)->andReturn('infinity');
        $this->assertEquals('first', $this->mock->foo(2));
        $this->assertEquals('second/third', $this->mock->foo(2));
        $this->assertEquals('second/third', $this->mock->foo(2));
        $this->assertEquals('infinity', $this->mock->foo(2));
        $this->assertEquals('infinity', $this->mock->foo(2));
        $this->assertEquals('infinity', $this->mock->foo(2));
        $this->container->mockery_verify();
    }

    public function testExpectationsCanBeMarkedAsDefaults()
    {
        $this->mock->shouldReceive('foo')->andReturn('bar')->byDefault();
        $this->assertEquals('bar', $this->mock->foo());
        $this->container->mockery_verify();
    }

    public function testDefaultExpectationsValidatedInCorrectOrder()
    {
        $this->mock->shouldReceive('foo')->with(1)->once()->andReturn('first')->byDefault();
        $this->mock->shouldReceive('foo')->with(2)->once()->andReturn('second')->byDefault();
        $this->assertEquals('first', $this->mock->foo(1));
        $this->assertEquals('second', $this->mock->foo(2));
        $this->container->mockery_verify();
    }

    public function testDefaultExpectationsAreReplacedByLaterConcreteExpectations()
    {
        $this->mock->shouldReceive('foo')->andReturn('bar')->once()->byDefault();
        $this->mock->shouldReceive('foo')->andReturn('bar')->twice();
        $this->mock->foo();
        $this->mock->foo();
        $this->container->mockery_verify();
    }

    public function testDefaultExpectationsCanBeChangedByLaterExpectations()
    {
        $this->mock->shouldReceive('foo')->with(1)->andReturn('bar')->once()->byDefault();
        $this->mock->shouldReceive('foo')->with(2)->andReturn('baz')->once();
        try {
            $this->mock->foo(1);
            $this->fail('Expected exception not thrown');
        } catch (\Mockery\Exception $e) {
        }
        $this->mock->foo(2);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testDefaultExpectationsCanBeOrdered()
    {
        $this->mock->shouldReceive('foo')->ordered()->byDefault();
        $this->mock->shouldReceive('bar')->ordered()->byDefault();
        $this->mock->bar();
        $this->mock->foo();
        $this->container->mockery_verify();
    }

    public function testDefaultExpectationsCanBeOrderedAndReplaced()
    {
        $this->mock->shouldReceive('foo')->ordered()->byDefault();
        $this->mock->shouldReceive('bar')->ordered()->byDefault();
        $this->mock->shouldReceive('bar')->ordered();
        $this->mock->shouldReceive('foo')->ordered();
        $this->mock->bar();
        $this->mock->foo();
        $this->container->mockery_verify();
    }

    public function testByDefaultOperatesFromMockConstruction()
    {
        $container = new \Mockery\Container(\Mockery::getDefaultGenerator(), \Mockery::getDefaultLoader());
        $mock = $container->mock('f', array('foo'=>'rfoo', 'bar'=>'rbar', 'baz'=>'rbaz'))->byDefault();
        $mock->shouldReceive('foo')->andReturn('foobar');
        $this->assertEquals('foobar', $mock->foo());
        $this->assertEquals('rbar', $mock->bar());
        $this->assertEquals('rbaz', $mock->baz());
        $mock->mockery_verify();
    }

    public function testByDefaultOnAMockDoesSquatWithoutExpectations()
    {
        $container = new \Mockery\Container(\Mockery::getDefaultGenerator(), \Mockery::getDefaultLoader());
        $mock = $container->mock('f')->byDefault();
    }

    public function testDefaultExpectationsCanBeOverridden()
    {
        $this->mock->shouldReceive('foo')->with('test')->andReturn('bar')->byDefault();
        $this->mock->shouldReceive('foo')->with('test')->andReturn('newbar')->byDefault();
        $this->mock->foo('test');
        $this->assertEquals('newbar', $this->mock->foo('test'));
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testByDefaultPreventedFromSettingDefaultWhenDefaultingExpectationWasReplaced()
    {
        $exp = $this->mock->shouldReceive('foo')->andReturn(1);
        $this->mock->shouldReceive('foo')->andReturn(2);
        $exp->byDefault();
    }

    /**
     * Argument Constraint Tests
     */

    public function testAnyConstraintMatchesAnyArg()
    {
        $this->mock->shouldReceive('foo')->with(1, Mockery::any())->twice();
        $this->mock->foo(1, 2);
        $this->mock->foo(1, 'str');
        $this->container->mockery_verify();
    }

    public function testAnyConstraintNonMatchingCase()
    {
        $this->mock->shouldReceive('foo')->times(3);
        $this->mock->shouldReceive('foo')->with(1, Mockery::any())->never();
        $this->mock->foo();
        $this->mock->foo(1);
        $this->mock->foo(1, 2, 3);
        $this->container->mockery_verify();
    }

    public function testArrayConstraintMatchesArgument()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::type('array'))->once();
        $this->mock->foo(array());
        $this->container->mockery_verify();
    }

    public function testArrayConstraintNonMatchingCase()
    {
        $this->mock->shouldReceive('foo')->times(3);
        $this->mock->shouldReceive('foo')->with(1, Mockery::type('array'))->never();
        $this->mock->foo();
        $this->mock->foo(1);
        $this->mock->foo(1, 2, 3);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testArrayConstraintThrowsExceptionWhenConstraintUnmatched()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::type('array'))->once();
        $this->mock->foo(1);
        $this->container->mockery_verify();
    }

    public function testBoolConstraintMatchesArgument()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::type('bool'))->once();
        $this->mock->foo(true);
        $this->container->mockery_verify();
    }

    public function testBoolConstraintNonMatchingCase()
    {
        $this->mock->shouldReceive('foo')->times(3);
        $this->mock->shouldReceive('foo')->with(1, Mockery::type('bool'))->never();
        $this->mock->foo();
        $this->mock->foo(1);
        $this->mock->foo(1, 2, 3);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testBoolConstraintThrowsExceptionWhenConstraintUnmatched()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::type('bool'))->once();
        $this->mock->foo(1);
        $this->container->mockery_verify();
    }

    public function testCallableConstraintMatchesArgument()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::type('callable'))->once();
        $this->mock->foo(function () {return 'f';});
        $this->container->mockery_verify();
    }

    public function testCallableConstraintNonMatchingCase()
    {
        $this->mock->shouldReceive('foo')->times(3);
        $this->mock->shouldReceive('foo')->with(1, Mockery::type('callable'))->never();
        $this->mock->foo();
        $this->mock->foo(1);
        $this->mock->foo(1, 2, 3);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testCallableConstraintThrowsExceptionWhenConstraintUnmatched()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::type('callable'))->once();
        $this->mock->foo(1);
        $this->container->mockery_verify();
    }

    public function testDoubleConstraintMatchesArgument()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::type('double'))->once();
        $this->mock->foo(2.25);
        $this->container->mockery_verify();
    }

    public function testDoubleConstraintNonMatchingCase()
    {
        $this->mock->shouldReceive('foo')->times(3);
        $this->mock->shouldReceive('foo')->with(1, Mockery::type('double'))->never();
        $this->mock->foo();
        $this->mock->foo(1);
        $this->mock->foo(1, 2, 3);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testDoubleConstraintThrowsExceptionWhenConstraintUnmatched()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::type('double'))->once();
        $this->mock->foo(1);
        $this->container->mockery_verify();
    }

    public function testFloatConstraintMatchesArgument()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::type('float'))->once();
        $this->mock->foo(2.25);
        $this->container->mockery_verify();
    }

    public function testFloatConstraintNonMatchingCase()
    {
        $this->mock->shouldReceive('foo')->times(3);
        $this->mock->shouldReceive('foo')->with(1, Mockery::type('float'))->never();
        $this->mock->foo();
        $this->mock->foo(1);
        $this->mock->foo(1, 2, 3);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testFloatConstraintThrowsExceptionWhenConstraintUnmatched()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::type('float'))->once();
        $this->mock->foo(1);
        $this->container->mockery_verify();
    }

    public function testIntConstraintMatchesArgument()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::type('int'))->once();
        $this->mock->foo(2);
        $this->container->mockery_verify();
    }

    public function testIntConstraintNonMatchingCase()
    {
        $this->mock->shouldReceive('foo')->times(3);
        $this->mock->shouldReceive('foo')->with(1, Mockery::type('int'))->never();
        $this->mock->foo();
        $this->mock->foo(1);
        $this->mock->foo(1, 2, 3);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testIntConstraintThrowsExceptionWhenConstraintUnmatched()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::type('int'))->once();
        $this->mock->foo('f');
        $this->container->mockery_verify();
    }

    public function testLongConstraintMatchesArgument()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::type('long'))->once();
        $this->mock->foo(2);
        $this->container->mockery_verify();
    }

    public function testLongConstraintNonMatchingCase()
    {
        $this->mock->shouldReceive('foo')->times(3);
        $this->mock->shouldReceive('foo')->with(1, Mockery::type('long'))->never();
        $this->mock->foo();
        $this->mock->foo(1);
        $this->mock->foo(1, 2, 3);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testLongConstraintThrowsExceptionWhenConstraintUnmatched()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::type('long'))->once();
        $this->mock->foo('f');
        $this->container->mockery_verify();
    }

    public function testNullConstraintMatchesArgument()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::type('null'))->once();
        $this->mock->foo(null);
        $this->container->mockery_verify();
    }

    public function testNullConstraintNonMatchingCase()
    {
        $this->mock->shouldReceive('foo')->times(3);
        $this->mock->shouldReceive('foo')->with(1, Mockery::type('null'))->never();
        $this->mock->foo();
        $this->mock->foo(1);
        $this->mock->foo(1, 2, 3);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testNullConstraintThrowsExceptionWhenConstraintUnmatched()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::type('null'))->once();
        $this->mock->foo('f');
        $this->container->mockery_verify();
    }

    public function testNumericConstraintMatchesArgument()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::type('numeric'))->once();
        $this->mock->foo('2');
        $this->container->mockery_verify();
    }

    public function testNumericConstraintNonMatchingCase()
    {
        $this->mock->shouldReceive('foo')->times(3);
        $this->mock->shouldReceive('foo')->with(1, Mockery::type('numeric'))->never();
        $this->mock->foo();
        $this->mock->foo(1);
        $this->mock->foo(1, 2, 3);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testNumericConstraintThrowsExceptionWhenConstraintUnmatched()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::type('numeric'))->once();
        $this->mock->foo('f');
        $this->container->mockery_verify();
    }

    public function testObjectConstraintMatchesArgument()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::type('object'))->once();
        $this->mock->foo(new stdClass);
        $this->container->mockery_verify();
    }

    public function testObjectConstraintNonMatchingCase()
    {
        $this->mock->shouldReceive('foo')->times(3);
        $this->mock->shouldReceive('foo')->with(1, Mockery::type('object`'))->never();
        $this->mock->foo();
        $this->mock->foo(1);
        $this->mock->foo(1, 2, 3);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testObjectConstraintThrowsExceptionWhenConstraintUnmatched()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::type('object'))->once();
        $this->mock->foo('f');
        $this->container->mockery_verify();
    }

    public function testRealConstraintMatchesArgument()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::type('real'))->once();
        $this->mock->foo(2.25);
        $this->container->mockery_verify();
    }

    public function testRealConstraintNonMatchingCase()
    {
        $this->mock->shouldReceive('foo')->times(3);
        $this->mock->shouldReceive('foo')->with(1, Mockery::type('real'))->never();
        $this->mock->foo();
        $this->mock->foo(1);
        $this->mock->foo(1, 2, 3);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testRealConstraintThrowsExceptionWhenConstraintUnmatched()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::type('real'))->once();
        $this->mock->foo('f');
        $this->container->mockery_verify();
    }

    public function testResourceConstraintMatchesArgument()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::type('resource'))->once();
        $r = fopen(dirname(__FILE__) . '/_files/file.txt', 'r');
        $this->mock->foo($r);
        $this->container->mockery_verify();
    }

    public function testResourceConstraintNonMatchingCase()
    {
        $this->mock->shouldReceive('foo')->times(3);
        $this->mock->shouldReceive('foo')->with(1, Mockery::type('resource'))->never();
        $this->mock->foo();
        $this->mock->foo(1);
        $this->mock->foo(1, 2, 3);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testResourceConstraintThrowsExceptionWhenConstraintUnmatched()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::type('resource'))->once();
        $this->mock->foo('f');
        $this->container->mockery_verify();
    }

    public function testScalarConstraintMatchesArgument()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::type('scalar'))->once();
        $this->mock->foo(2);
        $this->container->mockery_verify();
    }

    public function testScalarConstraintNonMatchingCase()
    {
        $this->mock->shouldReceive('foo')->times(3);
        $this->mock->shouldReceive('foo')->with(1, Mockery::type('scalar'))->never();
        $this->mock->foo();
        $this->mock->foo(1);
        $this->mock->foo(1, 2, 3);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testScalarConstraintThrowsExceptionWhenConstraintUnmatched()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::type('scalar'))->once();
        $this->mock->foo(array());
        $this->container->mockery_verify();
    }

    public function testStringConstraintMatchesArgument()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::type('string'))->once();
        $this->mock->foo('2');
        $this->container->mockery_verify();
    }

    public function testStringConstraintNonMatchingCase()
    {
        $this->mock->shouldReceive('foo')->times(3);
        $this->mock->shouldReceive('foo')->with(1, Mockery::type('string'))->never();
        $this->mock->foo();
        $this->mock->foo(1);
        $this->mock->foo(1, 2, 3);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testStringConstraintThrowsExceptionWhenConstraintUnmatched()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::type('string'))->once();
        $this->mock->foo(1);
        $this->container->mockery_verify();
    }

    public function testClassConstraintMatchesArgument()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::type('stdClass'))->once();
        $this->mock->foo(new stdClass);
        $this->container->mockery_verify();
    }

    public function testClassConstraintNonMatchingCase()
    {
        $this->mock->shouldReceive('foo')->times(3);
        $this->mock->shouldReceive('foo')->with(1, Mockery::type('stdClass'))->never();
        $this->mock->foo();
        $this->mock->foo(1);
        $this->mock->foo(1, 2, 3);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testClassConstraintThrowsExceptionWhenConstraintUnmatched()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::type('stdClass'))->once();
        $this->mock->foo(new Exception);
        $this->container->mockery_verify();
    }

    public function testDucktypeConstraintMatchesArgument()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::ducktype('quack', 'swim'))->once();
        $this->mock->foo(new Mockery_Duck);
        $this->container->mockery_verify();
    }

    public function testDucktypeConstraintNonMatchingCase()
    {
        $this->mock->shouldReceive('foo')->times(3);
        $this->mock->shouldReceive('foo')->with(1, Mockery::ducktype('quack', 'swim'))->never();
        $this->mock->foo();
        $this->mock->foo(1);
        $this->mock->foo(1, 2, 3);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testDucktypeConstraintThrowsExceptionWhenConstraintUnmatched()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::ducktype('quack', 'swim'))->once();
        $this->mock->foo(new Mockery_Duck_Nonswimmer);
        $this->container->mockery_verify();
    }

    public function testArrayContentConstraintMatchesArgument()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::subset(array('a'=>1, 'b'=>2)))->once();
        $this->mock->foo(array('a'=>1, 'b'=>2, 'c'=>3));
        $this->container->mockery_verify();
    }

    public function testArrayContentConstraintNonMatchingCase()
    {
        $this->mock->shouldReceive('foo')->times(3);
        $this->mock->shouldReceive('foo')->with(1, Mockery::subset(array('a'=>1, 'b'=>2)))->never();
        $this->mock->foo();
        $this->mock->foo(1);
        $this->mock->foo(1, 2, 3);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testArrayContentConstraintThrowsExceptionWhenConstraintUnmatched()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::subset(array('a'=>1, 'b'=>2)))->once();
        $this->mock->foo(array('a'=>1, 'c'=>3));
        $this->container->mockery_verify();
    }

    public function testContainsConstraintMatchesArgument()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::contains(1, 2))->once();
        $this->mock->foo(array('a'=>1, 'b'=>2, 'c'=>3));
        $this->container->mockery_verify();
    }

    public function testContainsConstraintNonMatchingCase()
    {
        $this->mock->shouldReceive('foo')->times(3);
        $this->mock->shouldReceive('foo')->with(1, Mockery::contains(1, 2))->never();
        $this->mock->foo();
        $this->mock->foo(1);
        $this->mock->foo(1, 2, 3);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testContainsConstraintThrowsExceptionWhenConstraintUnmatched()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::contains(1, 2))->once();
        $this->mock->foo(array('a'=>1, 'c'=>3));
        $this->container->mockery_verify();
    }

    public function testHasKeyConstraintMatchesArgument()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::hasKey('c'))->once();
        $this->mock->foo(array('a'=>1, 'b'=>2, 'c'=>3));
        $this->container->mockery_verify();
    }

    public function testHasKeyConstraintNonMatchingCase()
    {
        $this->mock->shouldReceive('foo')->times(3);
        $this->mock->shouldReceive('foo')->with(1, Mockery::hasKey('a'))->never();
        $this->mock->foo();
        $this->mock->foo(1);
        $this->mock->foo(1, array('a'=>1), 3);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testHasKeyConstraintThrowsExceptionWhenConstraintUnmatched()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::hasKey('c'))->once();
        $this->mock->foo(array('a'=>1, 'b'=>3));
        $this->container->mockery_verify();
    }

    public function testHasValueConstraintMatchesArgument()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::hasValue(1))->once();
        $this->mock->foo(array('a'=>1, 'b'=>2, 'c'=>3));
        $this->container->mockery_verify();
    }

    public function testHasValueConstraintNonMatchingCase()
    {
        $this->mock->shouldReceive('foo')->times(3);
        $this->mock->shouldReceive('foo')->with(1, Mockery::hasValue(1))->never();
        $this->mock->foo();
        $this->mock->foo(1);
        $this->mock->foo(1, array('a'=>1), 3);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testHasValueConstraintThrowsExceptionWhenConstraintUnmatched()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::hasValue(2))->once();
        $this->mock->foo(array('a'=>1, 'b'=>3));
        $this->container->mockery_verify();
    }

    public function testOnConstraintMatchesArgument_ClosureEvaluatesToTrue()
    {
        $function = function ($arg) {return $arg % 2 == 0;};
        $this->mock->shouldReceive('foo')->with(Mockery::on($function))->once();
        $this->mock->foo(4);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testOnConstraintThrowsExceptionWhenConstraintUnmatched_ClosureEvaluatesToFalse()
    {
        $function = function ($arg) {return $arg % 2 == 0;};
        $this->mock->shouldReceive('foo')->with(Mockery::on($function))->once();
        $this->mock->foo(5);
        $this->container->mockery_verify();
    }

    public function testMustBeConstraintMatchesArgument()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::mustBe(2))->once();
        $this->mock->foo(2);
        $this->container->mockery_verify();
    }

    public function testMustBeConstraintNonMatchingCase()
    {
        $this->mock->shouldReceive('foo')->times(3);
        $this->mock->shouldReceive('foo')->with(1, Mockery::mustBe(2))->never();
        $this->mock->foo();
        $this->mock->foo(1);
        $this->mock->foo(1, 2, 3);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testMustBeConstraintThrowsExceptionWhenConstraintUnmatched()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::mustBe(2))->once();
        $this->mock->foo('2');
        $this->container->mockery_verify();
    }

    public function testMustBeConstraintMatchesObjectArgumentWithEqualsComparisonNotIdentical()
    {
        $a = new stdClass;
        $a->foo = 1;
        $b = new stdClass;
        $b->foo = 1;
        $this->mock->shouldReceive('foo')->with(Mockery::mustBe($a))->once();
        $this->mock->foo($b);
        $this->container->mockery_verify();
    }

    public function testMustBeConstraintNonMatchingCaseWithObject()
    {
        $a = new stdClass;
        $a->foo = 1;
        $this->mock->shouldReceive('foo')->times(3);
        $this->mock->shouldReceive('foo')->with(1, Mockery::mustBe($a))->never();
        $this->mock->foo();
        $this->mock->foo(1);
        $this->mock->foo(1, $a, 3);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testMustBeConstraintThrowsExceptionWhenConstraintUnmatchedWithObject()
    {
        $a = new stdClass;
        $a->foo = 1;
        $b = new stdClass;
        $b->foo = 2;
        $this->mock->shouldReceive('foo')->with(Mockery::mustBe($a))->once();
        $this->mock->foo($b);
        $this->container->mockery_verify();
    }

    public function testMatchPrecedenceBasedOnExpectedCallsFavouringExplicitMatch()
    {
        $this->mock->shouldReceive('foo')->with(1)->once();
        $this->mock->shouldReceive('foo')->with(Mockery::any())->never();
        $this->mock->foo(1);
        $this->container->mockery_verify();
    }

    public function testMatchPrecedenceBasedOnExpectedCallsFavouringAnyMatch()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::any())->once();
        $this->mock->shouldReceive('foo')->with(1)->never();
        $this->mock->foo(1);
        $this->container->mockery_verify();
    }

    public function testReturnNullIfIgnoreMissingMethodsSet()
    {
        $this->mock->shouldIgnoreMissing();
        $this->assertNull($this->mock->g(1, 2));
    }

    public function testReturnUndefinedIfIgnoreMissingMethodsSet()
    {
        $this->mock->shouldIgnoreMissing()->asUndefined();
        $this->assertTrue($this->mock->g(1, 2) instanceof \Mockery\Undefined);
    }

    public function testReturnAsUndefinedAllowsForInfiniteSelfReturningChain()
    {
        $this->mock->shouldIgnoreMissing()->asUndefined();
        $this->assertTrue($this->mock->g(1, 2)->a()->b()->c() instanceof \Mockery\Undefined);
    }

    public function testShouldIgnoreMissingFluentInterface()
    {
        $this->assertTrue($this->mock->shouldIgnoreMissing() instanceof \Mockery\MockInterface);
    }

    public function testShouldIgnoreMissingAsUndefinedFluentInterface()
    {
        $this->assertTrue($this->mock->shouldIgnoreMissing()->asUndefined() instanceof \Mockery\MockInterface);
    }

    public function testShouldIgnoreMissingAsDefinedProxiesToUndefinedAllowingToString()
    {
        $this->mock->shouldIgnoreMissing()->asUndefined();
        $string = "Method call: {$this->mock->g()}";
        $string = "Mock: {$this->mock}";
    }

    public function testShouldIgnoreMissingDefaultReturnValue()
    {
        $this->mock->shouldIgnoreMissing(1);
        $this->assertEquals(1, $this->mock->a());
    }

    /** @issue #253 */
    public function testShouldIgnoreMissingDefaultSelfAndReturnsSelf()
    {
        $this->mock->shouldIgnoreMissing($this->container->self());
        $this->assertSame($this->mock, $this->mock->a()->b());
    }

    public function testToStringMagicMethodCanBeMocked()
    {
        $this->mock->shouldReceive("__toString")->andReturn('dave');
        $this->assertEquals("{$this->mock}", "dave");
    }

    public function testOptionalMockRetrieval()
    {
        $m = $this->container->mock('f')->shouldReceive('foo')->with(1)->andReturn(3)->mock();
        $this->assertTrue($m instanceof \Mockery\MockInterface);
    }

    public function testNotConstraintMatchesArgument()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::not(1))->once();
        $this->mock->foo(2);
        $this->container->mockery_verify();
    }

    public function testNotConstraintNonMatchingCase()
    {
        $this->mock->shouldReceive('foo')->times(3);
        $this->mock->shouldReceive('foo')->with(1, Mockery::not(2))->never();
        $this->mock->foo();
        $this->mock->foo(1);
        $this->mock->foo(1, 2, 3);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testNotConstraintThrowsExceptionWhenConstraintUnmatched()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::not(2))->once();
        $this->mock->foo(2);
        $this->container->mockery_verify();
    }

    public function testAnyOfConstraintMatchesArgument()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::anyOf(1, 2))->twice();
        $this->mock->foo(2);
        $this->mock->foo(1);
        $this->container->mockery_verify();
    }

    public function testAnyOfConstraintNonMatchingCase()
    {
        $this->mock->shouldReceive('foo')->times(3);
        $this->mock->shouldReceive('foo')->with(1, Mockery::anyOf(1, 2))->never();
        $this->mock->foo();
        $this->mock->foo(1);
        $this->mock->foo(1, 2, 3);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testAnyOfConstraintThrowsExceptionWhenConstraintUnmatched()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::anyOf(1, 2))->once();
        $this->mock->foo(3);
        $this->container->mockery_verify();
    }

    public function testNotAnyOfConstraintMatchesArgument()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::notAnyOf(1, 2))->once();
        $this->mock->foo(3);
        $this->container->mockery_verify();
    }

    public function testNotAnyOfConstraintNonMatchingCase()
    {
        $this->mock->shouldReceive('foo')->times(3);
        $this->mock->shouldReceive('foo')->with(1, Mockery::notAnyOf(1, 2))->never();
        $this->mock->foo();
        $this->mock->foo(1);
        $this->mock->foo(1, 4, 3);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testNotAnyOfConstraintThrowsExceptionWhenConstraintUnmatched()
    {
        $this->mock->shouldReceive('foo')->with(Mockery::notAnyOf(1, 2))->once();
        $this->mock->foo(2);
        $this->container->mockery_verify();
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testGlobalConfigMayForbidMockingNonExistentMethodsOnClasses()
    {
        \Mockery::getConfiguration()->allowMockingNonExistentMethods(false);
        $mock = $this->container->mock('stdClass');
        $mock->shouldReceive('foo');
    }

    /**
     * @expectedException \Mockery\Exception
     * @expectedExceptionMessage Mockery's configuration currently forbids mocking
     */
    public function testGlobalConfigMayForbidMockingNonExistentMethodsOnAutoDeclaredClasses()
    {
        \Mockery::getConfiguration()->allowMockingNonExistentMethods(false);
        $mock = $this->container->mock('SomeMadeUpClass');
        $mock->shouldReceive('foo');
    }

    /**
     * @expectedException \Mockery\Exception
     */
    public function testGlobalConfigMayForbidMockingNonExistentMethodsOnObjects()
    {
        \Mockery::getConfiguration()->allowMockingNonExistentMethods(false);
        $mock = $this->container->mock(new stdClass);
        $mock->shouldReceive('foo');
    }

    public function testAnExampleWithSomeExpectationAmends()
    {
        $service = $this->container->mock('MyService');
        $service->shouldReceive('login')->with('user', 'pass')->once()->andReturn(true);
        $service->shouldReceive('hasBookmarksTagged')->with('php')->once()->andReturn(false);
        $service->shouldReceive('addBookmark')->with('/^http:/', \Mockery::type('string'))->times(3)->andReturn(true);
        $service->shouldReceive('hasBookmarksTagged')->with('php')->once()->andReturn(true);

        $this->assertTrue($service->login('user', 'pass'));
        $this->assertFalse($service->hasBookmarksTagged('php'));
        $this->assertTrue($service->addBookmark('http://example.com/1', 'some_tag1'));
        $this->assertTrue($service->addBookmark('http://example.com/2', 'some_tag2'));
        $this->assertTrue($service->addBookmark('http://example.com/3', 'some_tag3'));
        $this->assertTrue($service->hasBookmarksTagged('php'));

        $this->container->mockery_verify();
    }

    public function testAnExampleWithSomeExpectationAmendsOnCallCounts()
    {
        $service = $this->container->mock('MyService');
        $service->shouldReceive('login')->with('user', 'pass')->once()->andReturn(true);
        $service->shouldReceive('hasBookmarksTagged')->with('php')->once()->andReturn(false);
        $service->shouldReceive('addBookmark')->with('/^http:/', \Mockery::type('string'))->times(3)->andReturn(true);
        $service->shouldReceive('hasBookmarksTagged')->with('php')->twice()->andReturn(true);

        $this->assertTrue($service->login('user', 'pass'));
        $this->assertFalse($service->hasBookmarksTagged('php'));
        $this->assertTrue($service->addBookmark('http://example.com/1', 'some_tag1'));
        $this->assertTrue($service->addBookmark('http://example.com/2', 'some_tag2'));
        $this->assertTrue($service->addBookmark('http://example.com/3', 'some_tag3'));
        $this->assertTrue($service->hasBookmarksTagged('php'));
        $this->assertTrue($service->hasBookmarksTagged('php'));

        $this->container->mockery_verify();
    }

    public function testAnExampleWithSomeExpectationAmendsOnCallCounts_PHPUnitTest()
    {
        $service = $this->getMock('MyService2');
        $service->expects($this->once())->method('login')->with('user', 'pass')->will($this->returnValue(true));
        $service->expects($this->exactly(3))->method('hasBookmarksTagged')->with('php')
            ->will($this->onConsecutiveCalls(false, true, true));
        $service->expects($this->exactly(3))->method('addBookmark')
            ->with($this->matchesRegularExpression('/^http:/'), $this->isType('string'))
            ->will($this->returnValue(true));

        $this->assertTrue($service->login('user', 'pass'));
        $this->assertFalse($service->hasBookmarksTagged('php'));
        $this->assertTrue($service->addBookmark('http://example.com/1', 'some_tag1'));
        $this->assertTrue($service->addBookmark('http://example.com/2', 'some_tag2'));
        $this->assertTrue($service->addBookmark('http://example.com/3', 'some_tag3'));
        $this->assertTrue($service->hasBookmarksTagged('php'));
        $this->assertTrue($service->hasBookmarksTagged('php'));
    }

    public function testMockedMethodsCallableFromWithinOriginalClass()
    {
        $mock = $this->container->mock('MockeryTest_InterMethod1[doThird]');
        $mock->shouldReceive('doThird')->andReturn(true);
        $this->assertTrue($mock->doFirst());
    }

    /**
     * @group issue #20
     */
    public function testMockingDemeterChainsPassesMockeryExpectationToCompositeExpectation()
    {
        $mock = $this->container->mock('Mockery_Demeterowski');
        $mock->shouldReceive('foo->bar->baz')->andReturn('Spam!');
        $demeter = new Mockery_UseDemeter($mock);
        $this->assertSame('Spam!', $demeter->doit());
    }

    /**
     * @group issue #20 - with args in demeter chain
     */
    public function testMockingDemeterChainsPassesMockeryExpectationToCompositeExpectationWithArgs()
    {
        $mock = $this->container->mock('Mockery_Demeterowski');
        $mock->shouldReceive('foo->bar->baz')->andReturn('Spam!');
        $demeter = new Mockery_UseDemeter($mock);
        $this->assertSame('Spam!', $demeter->doitWithArgs());
    }

    public function testPassthruEnsuresRealMethodCalledForReturnValues()
    {
        $mock = $this->container->mock('MockeryTest_SubjectCall1');
        $mock->shouldReceive('foo')->once()->passthru();
        $this->assertEquals('bar', $mock->foo());
        $this->container->mockery_verify();
    }

    public function testShouldIgnoreMissingExpectationBasedOnArgs()
    {
        $mock = $this->container->mock("MyService2")->shouldIgnoreMissing();
        $mock->shouldReceive("hasBookmarksTagged")->with("dave")->once();
        $mock->hasBookmarksTagged("dave");
        $mock->hasBookmarksTagged("padraic");
        $this->container->mockery_verify();
    }

    public function testShouldDeferMissingExpectationBasedOnArgs()
    {
        $mock = $this->container->mock("MockeryTest_SubjectCall1")->shouldDeferMissing();

        $this->assertEquals('bar', $mock->foo());
        $this->assertEquals('bar', $mock->foo("baz"));
        $this->assertEquals('bar', $mock->foo("qux"));

        $mock->shouldReceive("foo")->with("baz")->twice()->andReturn('123');
        $this->assertEquals('bar', $mock->foo());
        $this->assertEquals('123', $mock->foo("baz"));
        $this->assertEquals('bar', $mock->foo("qux"));

        $mock->shouldReceive("foo")->withNoArgs()->once()->andReturn('456');
        $this->assertEquals('456', $mock->foo());
        $this->assertEquals('123', $mock->foo("baz"));
        $this->assertEquals('bar', $mock->foo("qux"));

        $this->container->mockery_verify();
    }

    public function testCanReturnSelf()
    {
        $this->mock->shouldReceive("foo")->andReturnSelf();
        $this->assertSame($this->mock, $this->mock->foo());
    }

    public function testExpectationCanBeOverridden()
    {
        $this->mock->shouldReceive('foo')->once()->andReturn('green');
        $this->mock->shouldReceive('foo')->andReturn('blue');
        $this->assertEquals($this->mock->foo(), 'green');
        $this->assertEquals($this->mock->foo(), 'blue');
    }
}

class MockeryTest_SubjectCall1
{
    public function foo()
    {
        return 'bar';
    }
}

class MockeryTest_InterMethod1
{
    public function doFirst()
    {
        return $this->doSecond();
    }

    private function doSecond()
    {
        return $this->doThird();
    }

    public function doThird()
    {
        return false;
    }
}

class MyService2
{
    public function login($user, $pass)
    {
    }
    public function hasBookmarksTagged($tag)
    {
    }
    public function addBookmark($uri, $tag)
    {
    }
}

class Mockery_Duck
{
    public function quack()
    {
    }
    public function swim()
    {
    }
}

class Mockery_Duck_Nonswimmer
{
    public function quack()
    {
    }
}

class Mockery_Demeterowski
{
    public function foo()
    {
        return $this;
    }
    public function bar()
    {
        return $this;
    }
    public function baz()
    {
        return 'Ham!';
    }
}

class Mockery_UseDemeter
{
    public function __construct($demeter)
    {
        $this->demeter = $demeter;
    }
    public function doit()
    {
        return $this->demeter->foo()->bar()->baz();
    }
    public function doitWithArgs()
    {
        return $this->demeter->foo("foo")->bar("bar")->baz("baz");
    }
}

class MockeryTest_Foo
{
    public function foo()
    {
    }
}
