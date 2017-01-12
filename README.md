# :taco: Taco :taco:


This repository serves as an example for building larger Single-Page Applications (SPAs) in Elm 0.18. The main focus is what we call the _Taco_ model. Taco can be used to provide some application-wide information to all the modules that need it. In this example we have the current time, as well as translations (I18n) in the taco. In a real application, you would likely have the current logged-in user in the taco.

### Why the name?

We wanted to avoid names that have strong programming related connotations already. According to [Wikipedia](https://en.wikipedia.org/wiki/Taco):

> A taco is a traditional Mexican dish composed of a corn or wheat tortilla folded or rolled around a filling. A taco can be made with a variety of fillings, including beef, pork, chicken, seafood, vegetables and cheese, allowing for great versatility and variety.

What we mean by taco is also a vessel for tasty fillings, allowing for great versatility and variety. Plus, taco is short and memorable.


## What's the big :taco: idea?

Oftentimes in web applications there are some things that are singular and common by nature. The current time is an easy example of this. Of course we could have each module find out the current time on their own, but it does make sense to only handle that stuff in one place. Especially when the shared information is something like the translation files in our example app, it becomes apparent that retrieving the same file in every module would be a waste of time and resources.

How we've solved this in Elm is by introducing an extra parameter in the `view` functions:

```elm
view : Taco -> Model -> Html Msg
```

That's it, really.

The Taco is managed at the top-most module in the module hierarchy (`Main`), and its children, and their children, can politely ask for the Taco to be updated.

If need be, the Taco can just as well be given as a parameter to childrens' `init` and/or `update` functions. Most of the time it is not necessary, though, as is the case in this example application.


## How to try :taco:

There is a live demo here: [https://ohanhi.github.io/elm-taco/](https://ohanhi.github.io/elm-taco/)

To set up on your own computer, you will need `git`, `elm-0.18`, `node.js`, `yarnpkg`.

Also web browser with support of [Object.assign](https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Global_Objects/Object/assign) for loading `env.js`. There is also [polyfill](https://github.com/sindresorhus/object-assign).

Simply clone the repository and:


```bash
$ git clone https://github.com/rofrol/elm-taco-browsersync.git
$ cd elm-taco-browsersync
$ yarn
$ cp .env.example .env
$ ./tools/build-dev.sh
$ ./tools/server.js
```

In another terminal run:

```bash
$ ./tools/browsersync.js
```

Then navigate your browser to [http://localhost:8000](http://localhost:8000).

## Configuration

Based on https://12factor.net/config

```bash
cp .env.example .env
./tools/generate-env.js
```

You will get `dist/js/env.js` which is loaded to elm through flags.

## Linter elm make - don't compile twice

[There is a bug for that](https://github.com/mybuddymichael/linter-elm-make/issues/107).

In a file `~/.atom/packages/linter-elm-make/lib/linter-elm-make.js` change line

`let args = [inputFilePath, '--report=json', '--output=/dev/null', --yes'];`

to

`let args = [inputFilePath, '--report=json', '--output=dist/js/elm.js', '--debug', '--yes'];`

Restart atom.

You also need to setup main paths as is in `linter-elm-make.json` or run command as described in [Linter Elm Make: Set Main Paths](https://github.com/mybuddymichael/linter-elm-make#linter-elm-make-set-main-paths).

Also for me on Windows, linter-elm-make [couldn't use elm-make when elm installed from npm](https://github.com/mybuddymichael/linter-elm-make/issues/100). I had to install elm from executable.

## File structure

```bash
.
├── api                     # "Mock backend", serves localization files
│   ├── en.json
│   ├── fi.json
│   └── fi-formal.json
├── elm-package.json        # Definition of the project dependencies
├── LICENSE
├── linter-elm-make.json
├── package.json
├── README.md               # This documentation
├── src
│   ├──  elm
│   │   ├── Decoders.elm            # All JSON decoders
│   │   ├── I18n.elm                # Helpers for localized strings
│   │   ├── Main.elm                # Main handles the Taco and AppState
│   │   ├── Pages
│   │   │   ├── Home.elm                # A Page that uses the Taco
│   │   │   └── Settings.elm            # A Page that can change the Taco
│   │   ├── Routing
│   │   │   ├── Helpers.elm             # Definitions of routes and some helpers
│   │   │   └── Router.elm              # The parent for Pages, includes the base layout
│   │   ├── Styles.elm              # Some elm-css
│   │   └── Types.elm               # All shared types
│   ├── images
│   └── index.html              # The web page that initializes our app
│   └── styles
│       └── style.css
├── tools
│   ├── browsersync.js
│   ├── build-dev.sh
│   ├── build-non-elm.sh
│   ├── build-prod.sh
│   ├── clean.sh
│   ├── elm-make-dev.sh
│   ├── elm-make-prod.sh
│   ├── generate-env.js
│   └── server.js
└── yarn.lock
```


## How :taco: works

### Initializing the application

The most important file to look at is [`Main.elm`](https://github.com/ohanhi/elm-taco/blob/master/src/Main.elm). In this example app, the default set of translations is considered a prerequisite for starting the actual application. In your application, this might be the logged-in user's information, for example.

Our Model in Main is defined like so:

```elm
type alias Model =
    { appState : AppState
    , location : Location
    }

type AppState
    = NotReady Time
    | Ready Taco Router.Model
```

We can see that the application can either be `NotReady` and have just a `Time` as payload, or it can be `Ready`, in which case it will have a complete Taco as well as an initialized Router.

We are using [`programWithFlags`](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html#programWithFlags), which allows us to get the current time immediately from the [embedding code](https://github.com/ohanhi/elm-taco/blob/36a9a12/index.html#L16-L18). This could be used for initializing the app with some server-rendered JSON, as well.

This is how it works in the Elm side:

```elm
type alias Flags =
    { currentTime : Time
    }

init : Flags -> Location -> ( Model, Cmd Msg )
init flags location =
    ( { appState = NotReady flags.currentTime
      , location = location
      }
    , WebData.Http.get "/api/en.json" HandleTranslationsResponse Decoders.decodeTranslations
    )
```

We are using [`ohanhi/elm-web-data`](http://package.elm-lang.org/packages/ohanhi/elm-web-data/latest) for the HTTP connections. With WebData, we represent any data that we retrieve from a server as a type like this:

```elm
type WebData a
    = NotAsked
    | Loading
    | Failure (Error String)
    | Success a
```

If you're unsure what the benefit of this is, you should read Kris Jenkins' blog post: [
How Elm Slays a UI Antipattern](http://blog.jenkster.com/2016/06/how-elm-slays-a-ui-antipattern.html).


Now, by far the most interesting of the other functions is `updateTranslations`, because translations are the prerequisite for initializing the main application.

Let's split it up a bit to explain what's going on.


```elm
case webData of
    Failure _ ->
        Debug.crash "OMG CANT EVEN DOWNLOAD."
```

In this example application, we simply keel over if the initial request fails. In a real application, this case must be handled with e.g. retrying or using a "best guess" default.


```elm
    Success translations ->
```
Oh, jolly good, we got the translations we were looking for. Now all we need to do is either: a) initialize the whole thing, or b) update the current running application.

```elm
        case model.appState of
```
So if we don't have a ready app, let's create one now:

```elm
            NotReady time ->
                let
                    initTaco =
                        { currentTime = time
                        , translate = I18n.get translations
                        }

                    ( initRouterModel, routerCmd ) =
                        Router.init model.location
                in
                    ( { model | appState = Ready initTaco initRouterModel }
                    , Cmd.map RouterMsg routerCmd
                    )
```
Note that we use the `time` in the model to set the `initTaco`'s value, and we set the `translate` function based on the translations we just received. This taco is then set as a part of our `AppState`.

If we do have an app ready, let's update the taco while keeping the `routerModel` unchanged.

```elm
            Ready taco routerModel ->
                ( { model | appState = Ready (updateTaco taco (UpdateTranslations translations)) routerModel }
                , Cmd.none
                )
```



Just to make it clear, here's the whole function:

```elm
updateTranslations : Model -> WebData Translations -> ( Model, Cmd Msg )
updateTranslations model webData =
    case webData of
        Failure _ ->
            Debug.crash "OMG CANT EVEN DOWNLOAD."

        Success translations ->
            case model.appState of
                NotReady time ->
                    let
                        initTaco =
                            { currentTime = time
                            , translate = I18n.get translations
                            }

                        ( initRouterModel, routerCmd ) =
                            Router.init model.location
                    in
                        ( { model | appState = Ready initTaco initRouterModel }
                        , Cmd.map RouterMsg routerCmd
                        )

                Ready taco routerModel ->
                    ( { model | appState = Ready (updateTaco taco (UpdateTranslations translations)) routerModel }
                    , Cmd.none
                    )

        _ ->
            ( model, Cmd.none )
```

### Updating the Taco

We now know that the Taco is one half of what makes our application `Ready`, but how can we update the taco from some other place than the Main module? In [`Types.elm`](https://github.com/ohanhi/elm-taco/blob/master/src/Types.elm) we have the definition for `TacoUpdate`:

```elm
type TacoUpdate
    = NoUpdate
    | UpdateTime Time
    | UpdateTranslations Translations
```

And in [`Pages/Settings.elm`](https://github.com/ohanhi/elm-taco/blob/master/src/Pages/Settings.elm) we have the `update` function return one of them along with the typical `Model` and `Cmd Msg`:

```elm
update : Msg -> Model -> ( Model, Cmd Msg, TacoUpdate )
```

This obviously needs to be passed on also in the parent (`Router.elm`), which has the same signature for the update function. Then finally, back at the top level of our hierarchy, in the Main module we handle these requests to change the Taco for all modules.

```elm
updateRouter : Model -> Router.Msg -> ( Model, Cmd Msg )
updateRouter model routerMsg =
    case model.appState of
        Ready taco routerModel ->
            let
                ( nextRouterModel, routerCmd, tacoUpdate ) =
                    Router.update routerMsg routerModel

                nextTaco =
                    updateTaco taco tacoUpdate
            in
                ( { model | appState = Ready nextTaco nextRouterModel }
                , Cmd.map RouterMsg routerCmd
                )

-- ...

updateTaco : Taco -> TacoUpdate -> Taco
updateTaco taco tacoUpdate =
    case tacoUpdate of
        UpdateTime time ->
            { taco | currentTime = time }

        UpdateTranslations translations ->
            { taco | translate = I18n.get translations }

        NoUpdate ->
            taco
```

And that's it! I know it may be a little overwhelming, but take your time reading through the code and it will make sense. I promise. And if it doesn't, please put up an Issue so we can fix it!



## Credits and license

&copy; 2017 Ossi Hanhinen and Matias Klemola

Licensed under [BSD (3-clause)](LICENSE)
