module MainSpec exposing (suite)

import Expect
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Some test suite"
        [ Test.test "It works!" <|
            \_ ->
                Expect.equal 2 2
        ]
