module Action
    exposing
        ( changeDir
        , navigateHistory
        , changeTree
        , treeMutation
        , openItem
        , openInFinder
        , openInTerminal
        , toggleDisplayHiddenItem
        , recordSearchState
        , recordConfigTerminal
        , goToSettings
        , goToTree
        , changeDefaultTerminal
        , navigateHistoryFromMenu
        , toParentFromMenu
        )

{-| Provide all "action" of the application
-}

import Model exposing (Model, State(..))
import Message exposing (Message(..))
import Zipper.History as History exposing (History)
import File
import Port
import Simple.Fuzzy as Fuzzy
import SearchState exposing (SearchState(..))


{-| Go to the setting page
-}
goToSettings : Model -> ( Model, Cmd Message )
goToSettings model =
    let
        newModel =
            { model
                | state =
                    Configure { inputState = model.config.terminal }
            }
    in
        ( newModel, Cmd.none )


{-| Return to the tree page
-}
goToTree : Model -> ( Model, Cmd Message )
goToTree model =
    let
        newModel =
            { model | state = Explore }
    in
        ( newModel, Cmd.none )


{-| Change de Default Terminal
-}
changeDefaultTerminal : Model -> ( Model, Cmd Message )
changeDefaultTerminal model =
    case model.state of
        Explore ->
            ( model, Cmd.none )

        Configure state ->
            let
                config =
                    model.config

                newConfig =
                    { config | terminal = state.inputState }

                newModel =
                    { model | state = Explore, config = newConfig }
            in
                ( newModel, Port.changeTerminal newConfig )


{-| Filter hidden/not hidden files
-}
filterHidden : Bool -> File.Tree -> File.Tree
filterHidden showHidden tree =
    if not showHidden then
        List.filter (\f -> not f.hidden) tree
    else
        tree


{-| Filter by search
-}
filterSearch : String -> File.Tree -> File.Tree
filterSearch pred tree =
    if not (String.isEmpty pred) then
        Fuzzy.filter .name pred tree
    else
        tree


{-| Compute the "displayed" tree of a Model
-}
computeCurrentTree : Model -> Model
computeCurrentTree model =
    let
        newTree =
            model.realTree
                |> filterHidden model.displayHiddenItem
                |> filterSearch model.searchState
    in
        { model | currentTree = newTree }


{-| Clean the search field
-}
cleanSearchField : Model -> Model
cleanSearchField model =
    { model | searchState = "" }


{-| Track the input changement for terminal
-}
recordConfigTerminal : Model -> String -> ( Model, Cmd Message )
recordConfigTerminal model newTerminal =
    case model.state of
        Configure _ ->
            let
                newModel =
                    { model | state = Configure { inputState = newTerminal } }
            in
                ( newModel, Cmd.none )

        _ ->
            ( model, Cmd.none )


{-| Track the input changement for search
-}
recordSearchState : Model -> String -> ( Model, Cmd Message )
recordSearchState model newSearch =
    let
        path =
            Model.now model
    in
        case SearchState.nextStep path newSearch model.currentTree of
            ToParent dir ->
                changeDir model dir

            ToHome ->
                changeDir model model.homePath

            ToDir dir ->
                openItem model dir

            StayHere search ->
                let
                    newModel =
                        { model | searchState = search }
                            |> computeCurrentTree
                in
                    ( newModel, Cmd.none )


{-| Activate/Deactivate the display of Hidden Files/folders
-}
toggleDisplayHiddenItem : Model -> ( Model, Cmd Message )
toggleDisplayHiddenItem model =
    let
        newModel =
            { model | displayHiddenItem = not model.displayHiddenItem }
    in
        ( computeCurrentTree newModel, Cmd.none )


{-| Perform a "dir changement"
-}
changeDir : Model -> File.Path -> ( Model, Cmd Message )
changeDir model newPath =
    changeHistory model (\history -> History.push history newPath)


{-| Go to the parent from Electron
-}
toParentFromMenu : Model -> ( Model, Cmd Message )
toParentFromMenu model =
    case File.parent model.history.present of
        Nothing ->
            ( model, Cmd.none )

        Just parent ->
            changeDir model parent


{-| Navigate in the history (pred/next)
-}
navigateHistory : Model -> History File.Path -> ( Model, Cmd Message )
navigateHistory model newHistory =
    let
        newModel =
            { model | history = newHistory, state = Explore }
                |> cleanSearchField
    in
        ( newModel, Port.getTree (Model.now newModel) )


{-| Navigate in the history from Electron
-}
navigateHistoryFromMenu : Model -> Bool -> ( Model, Cmd Message )
navigateHistoryFromMenu model isPast =
    let
        f =
            if isPast then
                History.backward
            else
                History.forward
    in
        case f model.history of
            Just x ->
                navigateHistory model x

            Nothing ->
                ( model, Cmd.none )


{-| Change the current tree
-}
changeTree : Model -> File.Tree -> ( Model, Cmd Message )
changeTree model tree =
    let
        newModel =
            { model | realTree = tree, currentTree = tree }
                |> computeCurrentTree
    in
        ( newModel, Cmd.none )


{-| Change the current Tree if the file System watch an update
-}
treeMutation : Model -> Bool -> ( Model, Cmd Message )
treeMutation model flag =
    if flag then
        ( model, Port.getTree (Model.now model) )
    else
        ( model, Cmd.none )


{-| Open a folder or a file
-}
openItem : Model -> File.Item -> ( Model, Cmd Message )
openItem model file =
    if file.directory then
        changeDir model file.path
    else
        ( model, Port.openFile file.path )


{-| Open current Path into a finder
-}
openInFinder : Model -> ( Model, Cmd Message )
openInFinder model =
    let
        currentPath =
            Model.now model
    in
        ( model, Port.openInFinder currentPath )


{-| Open current Path into a terminal
-}
openInTerminal : Model -> ( Model, Cmd Message )
openInTerminal model =
    let
        currentPath =
            Model.now model

        terminal =
            model.config.terminal

        params =
            { app = terminal
            , path = currentPath
            }
    in
        ( model, Port.openInTerminal params )


{-| Perform a modification in the history using a function
-}
changeHistory : Model -> (History File.Path -> History File.Path) -> ( Model, Cmd Message )
changeHistory model f =
    let
        newModel =
            { model | history = f model.history, state = Explore }
                |> cleanSearchField
    in
        ( newModel, Port.getTree (Model.now newModel) )
