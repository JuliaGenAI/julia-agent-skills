---
name: tachikoma
description: Use when building terminal UI (TUI) applications in Julia with Tachikoma.jl. Also use when the user mentions Tachikoma, terminal apps, TUI in Julia, interactive terminal dashboards, text-based user interfaces, or wants to create CLI apps with widgets, layouts, animations, charts, forms, or pixel graphics in the terminal. Activate whenever someone wants to build any kind of interactive terminal application in Julia, even if they don't mention Tachikoma by name.
---

# Tachikoma.jl

Tachikoma.jl is a pure-Julia framework for building rich, interactive terminal applications. It provides an Elm-inspired `Model`/`update!`/`view` architecture, a 60fps event loop with double-buffered rendering, 30+ composable widgets, constraint-based layouts, animation primitives, kitty/sixel pixel graphics, and built-in recording and export to SVG/GIF.

Docs: https://kahliburke.github.io/Tachikoma.jl/dev/
Repo: https://github.com/kahliburke/Tachikoma.jl

For the complete widget catalog, layout API, animation system, async tasks, and testing reference, see `references/api-reference.md`.

## Installation

```julia
using Pkg
Pkg.add("Tachikoma")
```

Requires Julia 1.10+. For pixel graphics, use a Kitty or sixel-capable terminal (kitty, iTerm2, WezTerm, foot).

## Architecture: Model / Update / View

Every Tachikoma app follows the Elm architecture pattern. The three steps are always the same:

1. **Define a Model** — a `mutable struct <: Model` holding all application state
2. **Implement `update!`** — mutate the model in response to keyboard/mouse events
3. **Implement `view`** — render the full UI into a `Frame` each tick (60fps)

```julia
using Tachikoma
@tachikoma_app      # imports view, update!, should_quit etc. for extension
using Match          # optional but recommended for event handling

@kwdef mutable struct MyApp <: Model
    quit::Bool = false
    tick::Int = 0
    # ... your state fields ...
end

should_quit(m::MyApp) = m.quit

function update!(m::MyApp, evt::KeyEvent)
    @match (evt.key, evt.char) begin
        (:char, 'q') || (:escape, _) => (m.quit = true)
        _                             => nothing
    end
end

function view(m::MyApp, f::Frame)
    m.tick += 1
    buf = f.buffer
    area = f.area

    inner = render(Block(title="My App"), area, buf)
    set_string!(buf, inner.x, inner.y, "Hello, Tachikoma!", tstyle(:primary, bold=true))
end

app(MyApp())
```

### The `@tachikoma_app` macro

`@tachikoma_app` imports callback functions (`view`, `update!`, `should_quit`, `init!`, `cleanup!`, etc.) so you can define methods for them. Without it you'd need `import Tachikoma: view, update!, should_quit` or fully-qualified definitions like `Tachikoma.view(...)`.

### Protocol methods

| Method | Required | Purpose |
|--------|----------|---------|
| `view(model, frame)` | Yes | Render UI into frame's buffer |
| `update!(model, event)` | No | Handle keyboard/mouse/task events |
| `should_quit(model)` | No | Return `true` to exit (default: `false`) |
| `init!(model, terminal)` | No | One-time setup when app starts |
| `cleanup!(model)` | No | Teardown when app exits |
| `task_queue(model)` | No | Return a `TaskQueue` for async integration |

### Running the app

```julia
app(MyApp(); fps=60, default_bindings=true)
```

Default bindings: `Ctrl+C` quit, `Ctrl+\` theme selector, `Ctrl+G` toggle mouse, `Ctrl+A` toggle animations, `Ctrl+S` settings, `Ctrl+?` help.

## Layout System

Tachikoma uses constraint-based layouts. Create a `Layout` with a direction and constraints, split a `Rect`:

```julia
# Vertical: header + body + footer
rows = split_layout(Layout(Vertical, [Fixed(3), Fill(), Fixed(1)]), area)

# Horizontal: sidebar + main
cols = split_layout(Layout(Horizontal, [Percent(25), Fill()]), area)
```

**Constraints:** `Fixed(n)`, `Fill(weight)`, `Percent(p)`, `Min(n)`, `Max(n)`.

**Nesting** — split outer rects further:

```julia
rows = split_layout(Layout(Vertical, [Fixed(3), Fill(), Fixed(1)]), area)
cols = split_layout(Layout(Horizontal, [Percent(30), Fill()]), rows[2])
```

**Positioning helpers:**
- `center(parent, width, height)` — center a rect inside parent
- `anchor(parent, w, h; h=:center, v=:top)` — anchor by h/v alignment
- `inner(rect)` — shrink by 1 on all sides
- `margin(rect; top=0, right=0, bottom=0, left=0)`

**Container** — group widgets with automatic layout:

```julia
container = Container(
    [widget1, widget2, widget3],
    Layout(Vertical, [Fixed(3), Fill(), Fixed(1)]),
    Block(title="Panel")  # optional border
)
render(container, area, buf)
```

**ResizableLayout** — mouse-draggable pane borders:

```julia
rl = ResizableLayout(Horizontal, [Fixed(30), Fill()])
# In update!: handle_resize!(rl, mouse_event)
# In view: render_resize_handles!(buf, rl)
```

## Styling & Themes

Use `tstyle` to create styles from named theme slots:

```julia
tstyle(:primary)                    # themed primary color
tstyle(:primary, bold=true)         # with modifiers
tstyle(:accent)
tstyle(:error)
tstyle(:warning)
tstyle(:success)
tstyle(:border)
tstyle(:text)
tstyle(:text_dim)
```

11 built-in themes: `KOKAKU`, `ESPER`, `MOTOKO`, `KANEDA`, `NEUROMANCER`, `CATPPUCCIN`, `SOLARIZED`, `DRACULA`, `OUTRUN`, `ZENBURN`, `ICEBERG`. Users can hot-swap with `Ctrl+\`.

## Widget Quick Reference

All widgets follow the render protocol: `render(widget, area::Rect, buf::Buffer)`.

Interactive widgets use `handle_key!(widget, evt)` → returns `true` if consumed.

Value protocol: `value(widget)`, `set_value!(widget, v)`, `valid(widget)`.

| Category | Widgets |
|----------|---------|
| Text & Display | `Block`, `Paragraph`, `BigText`, `StatusBar`, `Span`, `Separator`, `MarkdownPane` |
| Input | `TextInput`, `TextArea`, `CodeEditor`, `Checkbox`, `RadioGroup`, `DropDown`, `Button` |
| Selection | `SelectableList`, `TabBar`, `TreeView`, `Calendar` |
| Data | `DataTable`, `Chart`, `BarChart`, `Sparkline`, `Gauge`, `ProgressList` |
| Layout | `Container`, `ScrollPane`, `Scrollbar`, `Modal`, `Form` |
| Graphics | `Canvas`, `BlockCanvas`, `PixelImage` |

### Common widget patterns

**Block** (bordered panel — the workhorse container):
```julia
inner = render(Block(title="Panel", border_style=tstyle(:border)), area, buf)
# `inner` is the usable Rect inside the border
```

**StatusBar** (bottom bar with left/right spans):
```julia
render(StatusBar(
    left=[Span("  [r]oll  ", tstyle(:accent))],
    right=[Span("[q]uit ", tstyle(:text_dim))],
), Rect(area.x, bottom(area), area.width, 1), buf)
```

**TextInput** with validation:
```julia
input = TextInput(; label="Name:", focused=true,
    validator=s -> isempty(s) ? "Required" : nothing)
handle_key!(input, evt)
text(input)  # current text
```

**Form** (multi-field with Tab navigation):
```julia
form = Form([
    FormField("Name", TextInput(; validator=s -> isempty(s) ? "Required" : nothing); required=true),
    FormField("Bio", TextArea()),
    FormField("Role", RadioGroup(["Admin", "Editor", "Viewer"])),
]; submit_label="Submit", block=Block(title="Registration"))
```

**Chart** (line/scatter):
```julia
series = [
    DataSeries(cpu_data; label="CPU", style=tstyle(:primary)),
    DataSeries(mem_data; label="Mem", style=tstyle(:secondary)),
]
render(Chart(series; block=Block(title="System")), area, buf)
```

**DataTable** (sortable, filterable):
```julia
dt = DataTable([
    DataColumn("Name", ["Alice", "Bob"]),
    DataColumn("Score", [95, 82]; align=col_right),
]; selected=1)
```

**FocusRing** (Tab/Shift-Tab navigation between widgets):
```julia
ring = FocusRing([widget1, widget2, widget3])
handle_key!(ring, evt)
current(ring)
```

## Buffer Drawing Primitives

```julia
set_char!(buf, x, y, '█', tstyle(:primary))
set_string!(buf, x, y, "Hello", tstyle(:accent, bold=true))
```

## Event Handling

Events are dispatched to `update!` by type:

```julia
function update!(m::MyApp, evt::KeyEvent)
    # evt.key :: Symbol  (:char, :enter, :escape, :up, :down, :left, :right, ...)
    # evt.char :: Char    (character for :char events, '\0' otherwise)
end

function update!(m::MyApp, evt::MouseEvent)
    # mouse clicks, scrolls, drags
end

function update!(m::MyApp, evt::TaskEvent)
    # async task results: evt.id :: Symbol, evt.value :: Any
end
```

Use `@match` from Match.jl for clean event routing:

```julia
@match (evt.key, evt.char) begin
    (:char, 'q') || (:escape, _) => (m.quit = true)
    (:up, _)                      => move_up!(m)
    (:down, _)                    => move_down!(m)
    _                              => nothing
end
```

## Animation

**Tweens** — interpolate between values over fixed frames:
```julia
tw = tween(0.0, 1.0; duration=60, easing=ease_out_cubic, loop=:pingpong)
advance!(tw); v = value(tw)
```

**Springs** — physics-based motion:
```julia
s = Spring(0.5; value=0.0, stiffness=180.0, damping=:critical)
advance!(s; dt=1.0/60.0); v = s.value
retarget!(s, new_target)  # smooth redirect mid-animation
```

**Timelines** — compose tweens: `sequence(...)`, `stagger(...; delay=5)`, `parallel(...)`.

**Animator** — per-model animation manager:
```julia
animate!(m.animator, :fade, tween(0.0, 1.0; duration=30))
tick!(m.animator)
val(m.animator, :fade)
```

**Organic effects:** `pulse`, `breathe`, `shimmer`, `jitter`, `flicker`, `drift`, `glow`, `noise`, `fbm`.

**Easing functions:** `linear`, `ease_in_quad`, `ease_out_quad`, `ease_in_out_quad`, `ease_in_cubic`, `ease_out_cubic`, `ease_in_out_cubic`, `ease_out_elastic`, `ease_out_bounce`, `ease_out_back`.

## Async Tasks

Background work that preserves the single-threaded Elm architecture:

```julia
@kwdef mutable struct MyApp <: Model
    tq::TaskQueue = TaskQueue()
    # ...
end

task_queue(m::MyApp) = m.tq  # tell framework about it

# Spawn a background task
spawn_task!(m.tq, :compute) do
    sleep(2.0)
    expensive_calculation()
end

# Handle results in update!
function update!(m::MyApp, evt::TaskEvent)
    if evt.id == :compute
        evt.value isa Exception ? handle_error(evt.value) : use_result(evt.value)
    end
end

# Timers
token = spawn_timer!(m.tq, :tick, 1.0; repeat=true)
cancel!(token)  # stop timer
```

Run Julia with threads for actual parallelism: `julia -t auto`.

## Testing with TestBackend

Headless widget testing without a real terminal:

```julia
using Test, Tachikoma
const T = Tachikoma

tb = T.TestBackend(80, 24)
T.render_widget!(tb, T.Paragraph("hello world"))

T.char_at(tb, 1, 1)          # → 'h'
T.row_text(tb, 1)             # → "hello world..."
T.find_text(tb, "world")      # → (x=7, y=1) or nothing
T.style_at(tb, 1, 1)          # → Style(...)

# Simulate key events
input = T.TextInput(text="hello", focused=true)
T.handle_key!(input, T.KeyEvent('!'))
@test T.text(input) == "hello!"

# Test model update!
T.update!(m, T.KeyEvent(:escape))
@test m.quit == true
```

## Recording & Export

```julia
# Live: press Ctrl+R during app to toggle recording
# Headless:
record_app(MyApp(); frames=120, path="demo.tach")
record_widget(widget, 80, 24; frames=60, path="widget.tach")
# Export:
# SVG and GIF export available (GIF needs FreeTypeAbstraction + ColorTypes)
```

## Optional Extensions

```julia
using CommonMark           # MarkdownPane rendering
using FreeTypeAbstraction, ColorTypes  # GIF export
using Tables               # Tables.jl → DataTable integration
```

## Backgrounds

Procedural animated backgrounds that composite behind your UI:

| Preset | Description |
|--------|-------------|
| `DotWave` | Undulating dot-matrix terrain |
| `PhyloTree` | Animated phylogenetic branching |
| `Cladogram` | Hierarchical cladogram trees |

## Gotchas

- **`@tachikoma_app` is required** if you want to define methods for `view`, `update!`, `should_quit` etc. Without it, you'd need explicit `import` or fully-qualified names.
- **`view` is called every frame** (~60fps). Construct widgets fresh each frame with current data — don't cache widget instances across frames.
- **`Block.render` returns inner Rect** — always capture it: `inner = render(Block(...), area, buf)`.
- **`StatusBar` pinned to bottom** — use `Rect(area.x, bottom(area), area.width, 1)` to place at terminal bottom edge.
- **Interactive widgets need `focused=true`** — `TextInput`, `CodeEditor` etc. ignore key events when not focused.
- **`handle_key!` returns `true` if consumed** — use this for event delegation in `FocusRing` or manual focus management.
- **Async tasks: don't mutate model in closures** — return results and let `update!(model, ::TaskEvent)` apply them on the main thread.
- **`julia -t auto`** needed for actual parallel async tasks.
