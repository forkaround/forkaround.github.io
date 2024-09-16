module MainSpec exposing (suite)

import Main exposing (Msg(..), view)
import Test exposing (Test)
import Test.Html.Event as Event
import Test.Html.Query as Query
import Test.Html.Selector as Html


suite : Test
suite =
    Test.describe "Main"
        [ Test.test "Displays the current count" <|
            \_ ->
                view 5
                    |> Query.fromHtml
                    |> Query.has [ Html.text "5" ]
        , Test.test "clicking on the + button sends an increment message" <|
            \_ ->
                view 0
                    |> Query.fromHtml
                    |> Query.find [ Html.tag "button", Html.containing [ Html.text "+" ] ]
                    |> Event.simulate Event.click
                    |> Event.expect Increment
        , Test.test "clicking on the - button sends a decrement message" <|
            \_ ->
                view 0
                    |> Query.fromHtml
                    |> Query.find [ Html.tag "button", Html.containing [ Html.text "-" ] ]
                    |> Event.simulate Event.click
                    |> Event.expect Decrement
        , Test.test "clicking the counter resets the count" <|
            \_ ->
                view 5
                    |> Query.fromHtml
                    |> Query.find [ Html.tag "button", Html.containing [ Html.text "5" ] ]
                    |> Event.simulate Event.click
                    |> Event.expect Reset
        ]
