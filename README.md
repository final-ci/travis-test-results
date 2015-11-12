Travis Test Results
===================

Process test results from Travis Worker (particularly travis-guest-api)
and store it in DB.


Implementation is based (copy & paste) from travis-logs (therefore 
travis-logs license is attached as well).

# Setup

     # if needed:
     dropdb travis_test_results_${ENV} --user ... --host .. --port ...
     createdb travis_test_results_${ENV} --user ... --host ...

     rake db:migrate

