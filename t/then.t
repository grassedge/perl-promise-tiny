package t::then;
use strict;
use warnings;

use parent qw(Test::Class);
use AnyEvent;
use Test::More;

use_ok 'Promise::Tiny';

sub then_success : Tests {
    my $test_value = 'first';

    my $cv = AnyEvent->condvar;
    Promise::Tiny->new(sub {
        my ($resolve, $reject) = @_;
        my $w; $w = AnyEvent->timer(
            after => 0.1,
            cb => sub {
                undef $w;
                is $test_value, 'first';
                $test_value = 'second';
                $resolve->('first resolve');
            }
        );
    })->then(sub {
        my ($value) = @_;
        is $value, 'first resolve';
        is $test_value, 'second';
        $test_value = 'third';
        return 'second resolve';
    })->then(sub {
        my ($value) = @_;
        is $value, 'second resolve';

        is $test_value, 'third';
        $test_value = 'forth';

        return Promise::Tiny->new(sub {
            my ($resolve, $reject) = @_;
            my $w; $w = AnyEvent->timer(
                after => 0.1,
                cb => sub {
                    undef $w;
                    is $test_value, 'forth';
                    $test_value = 'fifth';
                    $resolve->('third resolve');
                }
            );
        });
    })->then(sub {
        my ($value) = @_;
        is $value, 'third resolve';
        $cv->send;
    });
    $cv->recv;
}

sub then_success_with_no_handler : Tests {
    my $test_value = 'first';

    my $cv = AnyEvent->condvar;
    Promise::Tiny->new(sub {
        my ($resolve, $reject) = @_;
        my $w; $w = AnyEvent->timer(
            after => 0.1,
            cb => sub {
                undef $w;
                is $test_value, 'first';
                $test_value = 'second';
                $resolve->('first resolve');
                $cv->send;
            }
        );
    });
    $cv->recv;
}

sub already_resolved : Tests {
    my $called = 0;
    my $p = Promise::Tiny->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->('executed');
    })->then(sub {
        my ($value) = @_;
        $called = 'called';
    });
    is $called, 'called', 'call fulfilled callback if promise already reasolved';
}

__PACKAGE__->runtests;
