# Tachikoma.jl API Reference

Detailed reference for widgets, layout, animation, events, styling, and testing APIs.

Full online docs: https://kahliburke.github.io/Tachikoma.jl/dev/

## Table of Contents

1. [Widgets — Text & Display](#text--display-widgets)
2. [Widgets — Input](#input-widgets)
3. [Widgets — Selection & Navigation](#selection--navigation-widgets)
4. [Widgets — Data Visualization](#data-visualization-widgets)
5. [Widgets — Containers & Control](#containers--control-widgets)
6. [Layout API](#layout-api)
7. [Styling API](#styling-api)
8. [Animation API](#animation-api)
9. [Async Tasks API](#async-tasks-api)
10. [Events API](#events-api)
11. [Graphics API](#graphics-api)
12. [Testing API](#testing-api)
13. [Recording API](#recording-api)

---

## Text & Display Widgets

### Block

Bordered panel with optional title. Returns inner `Rect` after drawing borders.

```julia
block = Block(; title="Panel", border_style=tstyle(:border),
               title_style=tstyle(:title, bold=true), box=BOX_ROUNDED)
inner = render(block, area, buf)
```

Box styles: `BOX_ROUNDED`, `BOX_HEAVY`, `BOX_DOUBLE`, `BOX_PLAIN`.

### Paragraph

Styled text with wrapping and alignment:

```julia
para = Paragraph([
    Span("Bold text ", tstyle(:text, bold=true)),
    Span("and dim text", tstyle(:text_dim)),
]; wrap=word_wrap, alignment=align_center)
render(para, area, buf)
paragraph_line_count(para, 40)  # count wrapped lines for a given width
```

Wrap modes: `no_wrap`, `word_wrap`, `char_wrap`. Alignment: `align_left`, `align_center`, `align_right`.

### Span

Inline styled text fragment, used inside `Paragraph` and `StatusBar`:

```julia
Span("text", tstyle(:primary, bold=true))
```

### BigText

Large block-character text (5 rows tall):

```julia
bt = BigText("12:34"; style=tstyle(:primary, bold=true))
render(bt, area, buf)
intrinsic_size(bt)  # (width, height) in terminal cells
```

### StatusBar

Full-width bar with left and right aligned spans:

```julia
render(StatusBar(
    left=[Span("  Status: OK ", tstyle(:success))],
    right=[Span("[q] quit ", tstyle(:text_dim))],
), area, buf)
```

### Separator

Visual divider line:

```julia
render(Separator(), area, buf)
```

### MarkdownPane

Scrollable CommonMark viewer. Requires `enable_markdown()` or `using CommonMark`:

```julia
enable_markdown()
pane = MarkdownPane("# Hello\n\n**Bold**, *italic*, `code`.";
    block=Block(title="Docs"))
render(pane, area, buf)
set_markdown!(pane, "# Updated\nNew content.")
```

Supports keyboard scrolling and mouse wheel. Auto-reflows on width change.

---

## Input Widgets

### TextInput

Single-line text editor with optional validation:

```julia
input = TextInput(; text="initial", label="Name:", focused=true,
                   validator=s -> length(s) < 2 ? "Min 2 chars" : nothing)
handle_key!(input, evt)
text(input)               # get current text
set_text!(input, "new")   # set text
value(input)              # same as text()
valid(input)              # true if validator returns nothing
```

### TextArea

Multi-line text editor:

```julia
area = TextArea(; text="", label="Bio:", focused=true)
handle_key!(area, evt)
handle_mouse!(area, evt, rect)
text(area)
set_text!(area, "multi\nline")
```

### CodeEditor

Syntax-highlighted code editor with Julia tokenization:

```julia
ce = CodeEditor(; text="function greet(name)\n    println(\"Hello, \$name!\")\nend",
    focused=true, block=Block(title="editor.jl"))
handle_key!(ce, evt)
editor_mode(ce)  # current mode symbol
```

Token types: `token_keyword`, `token_string`, `token_comment`, `token_number`, `token_plain`.

### Checkbox

Boolean toggle:

```julia
cb = Checkbox("Enable notifications"; focused=false)
handle_key!(cb, evt)   # space toggles
value(cb)              # true/false
set_value!(cb, true)
```

### RadioGroup

Mutually exclusive selection:

```julia
rg = RadioGroup(["Admin", "Editor", "Viewer"])
handle_key!(rg, evt)   # up/down + space/enter
value(rg)              # selected index (Int)
set_value!(rg, 2)
```

### DropDown

Select from dropdown list:

```julia
dd = DropDown(["Tokyo", "Berlin", "NYC", "London"])
handle_key!(dd, evt)   # enter opens, up/down navigates, enter selects
value(dd)              # selected index (Int)
```

### Button

Clickable button:

```julia
btn = Button("Submit"; style=tstyle(:primary), focused=true)
render(btn, area, buf)
handle_key!(btn, evt)  # enter/space triggers
```

### Calendar

Date picker widget:

```julia
cal = Calendar(2026, 2; today=19)
render(cal, area, buf)
```

---

## Selection & Navigation Widgets

### SelectableList

Keyboard and mouse navigable list:

```julia
list = SelectableList(["Alpha", "Beta", "Gamma"];
    selected=1, focused=true,
    block=Block(title="Items"),
    highlight_style=tstyle(:accent, bold=true))
handle_key!(list, evt)
value(list)              # selected index
set_value!(list, 2)
```

Styled items:

```julia
items = [ListItem("Item 1", tstyle(:text)),
         ListItem("Item 2", tstyle(:warning))]
list = SelectableList(items; selected=1)
```

### TreeView / TreeNode

Hierarchical tree display:

```julia
root = TreeNode("Root", [
    TreeNode("Child 1", [TreeNode("Leaf A"), TreeNode("Leaf B")]),
    TreeNode("Child 2"),
])
tree = TreeView(root; block=Block(title="Tree"))
render(tree, area, buf)
handle_key!(tree, evt)  # up/down navigate, enter expand/collapse
```

### TabBar

Tab switching:

```julia
tabs = TabBar(["Overview", "Details", "Settings"]; active=2)
render(tabs, area, buf)
handle_key!(tabs, evt)  # left/right
value(tabs)             # selected tab index
```

### Modal

Confirmation dialog:

```julia
modal = Modal(; title="Delete?", message="This cannot be undone.",
               confirm_label="Delete", cancel_label="Cancel", selected=:cancel)
render(modal, area, buf)
```

---

## Data Visualization Widgets

### Sparkline

Mini line chart from a data vector:

```julia
Sparkline(data; style=tstyle(:accent))
```

### Gauge

Progress bar (0.0 to 1.0):

```julia
Gauge(progress; filled_style=tstyle(:primary),
    empty_style=tstyle(:text_dim, dim=true), tick=tick)
```

### BarChart

Bar chart with labeled entries:

```julia
entries = [BarEntry("CPU", 65.0), BarEntry("MEM", 42.0), BarEntry("DSK", 78.0)]
render(BarChart(entries; block=Block(title="Usage")), area, buf)
```

### Chart

Line and scatter plots with multiple series:

```julia
series = [
    DataSeries(cpu_data; label="CPU", style=tstyle(:primary)),
    DataSeries(mem_data; label="Mem", style=tstyle(:secondary)),
]
render(Chart(series; block=Block(title="System")), area, buf)
```

Chart types: `chart_line`, `chart_scatter`.

### Table

Simple row/column table:

```julia
headers = ["Name", "Status", "CPU"]
rows = [["nginx", "running", "12%"], ["postgres", "running", "8%"]]
render(Table(headers, rows;
    block=Block(title="Processes"),
    header_style=tstyle(:title, bold=true),
    row_style=tstyle(:text),
    alt_row_style=tstyle(:text_dim)), area, buf)
```

### DataTable

Sortable, filterable data table with pagination:

```julia
dt = DataTable([
    DataColumn("Name", ["Alice", "Bob", "Carol"]),
    DataColumn("Score", [95, 82, 91]; align=col_right),
    DataColumn("Grade", ["A", "B", "A"]; align=col_center),
]; selected=1)
```

Sort directions: `sort_none`, `sort_asc`, `sort_desc`. Column alignment: `col_left`, `col_right`, `col_center`.

Tables.jl integration:

```julia
using Tables
dt = DataTable(my_dataframe)
```

### ProgressList / ProgressItem

Task status list:

```julia
items = [
    ProgressItem("Build"; status=task_done),
    ProgressItem("Test"; status=task_running),
    ProgressItem("Deploy"; status=task_pending),
]
render(ProgressList(items; tick=tick), area, buf)
```

Statuses: `task_pending`, `task_running`, `task_done`, `task_error`, `task_skipped`.

---

## Containers & Control Widgets

### Form / FormField

Multi-field form with Tab navigation and validation:

```julia
form = Form([
    FormField("Name", TextInput(; validator=s -> isempty(s) ? "Required" : nothing); required=true),
    FormField("Bio", TextArea()),
    FormField("Notify", Checkbox("Enable notifications")),
    FormField("Role", RadioGroup(["Admin", "Editor", "Viewer"])),
    FormField("City", DropDown(["Tokyo", "Berlin", "NYC"])),
]; submit_label="Submit", block=Block(title="Registration"))

handle_key!(form, evt)  # Tab/Shift-Tab navigation
value(form)             # Dict{String, Any} of field label → value
valid(form)             # true if all required fields are valid
```

### ScrollPane

Scrollable container for content:

```julia
sp = ScrollPane(["Line 1", "Line 2"]; following=true)
push_line!(sp, "new line")
render(sp, area, buf)
handle_mouse!(sp, evt, area)
```

### FocusRing

Tab/Shift-Tab navigation manager:

```julia
ring = FocusRing([widget1, widget2, widget3])
handle_key!(ring, evt)
current(ring)
next!(ring)
prev!(ring)
```

### Container

Group widgets with automatic layout:

```julia
container = Container(
    [widget1, widget2, widget3],
    Layout(Vertical, [Fixed(3), Fill(), Fixed(1)]),
    Block(title="Panel")  # optional
)
render(container, area, buf)
```

---

## Layout API

### Rect

```julia
r = Rect(x, y, width, height)  # 1-based coordinates
right(r)                        # r.x + r.width - 1
bottom(r)                       # r.y + r.height - 1
inner(r)                        # shrink by 1 on all sides
margin(r; top=0, right=0, bottom=0, left=0)
shrink(r, n)                    # uniform margin
center(parent, width, height)   # center a rect inside parent
anchor(parent, w, h; h=:center, v=:center)  # anchor by alignment
```

### Layout / split_layout

```julia
Layout(direction, constraints; align=layout_start)
rects = split_layout(layout, rect)
```

Directions: `Vertical`, `Horizontal`.

Constraints: `Fixed(n)`, `Fill(weight)`, `Percent(p)`, `Min(n)`, `Max(n)`.

Alignment: `layout_start`, `layout_center`, `layout_end`, `layout_space_between`.

### ResizableLayout

```julia
rl = ResizableLayout(direction, constraints; min_pane_size=3)
split_layout(rl, rect)
handle_resize!(rl, mouse_evt)      # returns true if consumed
reset_layout!(rl)                   # restore original constraints
render_resize_handles!(buf, rl)     # draw visual feedback
```

### intrinsic_size protocol

Widgets with natural size: `intrinsic_size(widget) → (width, height)` or `nothing`.

```julia
Tachikoma.intrinsic_size(w::MyWidget) = (length(w.text), 1)
```

---

## Styling API

```julia
tstyle(:primary)                    # theme slot
tstyle(:primary, bold=true)         # with modifier
Style(fg=ColorRGB(0xff, 0x00, 0x00), bold=true)  # explicit color
color_lerp(color1, color2, t)       # interpolate colors
to_rgb(theme_color)                 # convert theme color to ColorRGB
theme()                             # get current theme
```

Theme slots: `:primary`, `:secondary`, `:accent`, `:success`, `:warning`, `:error`, `:border`, `:title`, `:text`, `:text_dim`.

Modifiers: `bold`, `dim`, `italic`, `underline`, `reverse`.

---

## Animation API

### Tweens

```julia
tw = tween(start, stop; duration=60, easing=ease_out_cubic, loop=:none)
advance!(tw)
value(tw)
done(tw)
reset!(tw)
```

Loop modes: `:none`, `:loop`, `:pingpong`.

### Springs

```julia
s = Spring(target; value=0.0, stiffness=180.0, damping=:critical)
advance!(s; dt=1.0/60.0)
s.value
settled(s; threshold=0.01)
retarget!(s, new_target)  # smooth redirect
```

Damping: `:critical`, `:over`, `:under`, or explicit `Float64`.

### Timelines

```julia
sequence(tween1, tween2, ...)         # play one after another
stagger(tween1, tween2; delay=5)      # overlapping starts
parallel(tween1, tween2, ...)         # all at once
advance!(timeline)
done(timeline)
```

### Animator

```julia
anim = Animator()
animate!(anim, :name, tween_or_spring_or_timeline)
tick!(anim)
val(anim, :name) → Float64
```

### Organic Effects

```julia
noise(x)                                    # 1D noise ∈ [0,1]
noise(x, y)                                 # 2D noise
fbm(x; octaves=3, lacunarity=2.0, gain=0.5)

pulse(tick; period=60, lo=0.3, hi=1.0)
breathe(tick; period=90)
shimmer(tick, x; speed=0.08, scale=0.15)
jitter(tick, seed; amount=0.5, speed=0.1)
flicker(tick, seed=0; intensity=0.1, speed=0.15)
drift(tick, seed=0; speed=0.02)
glow(x, y, cx, cy; radius=5.0, falloff=2.0)
color_wave(tick, x, colors; speed=0.04, spread=0.08)
```

### Buffer Fills

```julia
fill_gradient!(buf, rect, color1, color2; direction=:horizontal)
fill_noise!(buf, rect, color1, color2, tick; scale=0.2, speed=0.03)
border_shimmer!(buf, rect, base_color, tick; box=BOX_ROUNDED, intensity=0.15)
```

### Global Toggle

```julia
animations_enabled() → Bool
toggle_animations!()
```

---

## Async Tasks API

### TaskQueue

```julia
tq = TaskQueue()
task_queue(m::MyModel) = m.tq  # override to enable
```

### spawn_task!

```julia
spawn_task!(tq, :id) do
    # runs in background thread
    expensive_work()
end
```

### spawn_timer!

```julia
token = spawn_timer!(tq, :tick, 1.0; repeat=true)
cancel!(token)
is_cancelled(token)
```

### TaskEvent

```julia
function update!(m::MyModel, evt::TaskEvent)
    # evt.id :: Symbol
    # evt.value :: Any (result or Exception)
end
```

### Active count

```julia
m.tq.active[]  # atomic read of running task count
```

---

## Events API

### KeyEvent

```julia
KeyEvent('a')            # character key
KeyEvent(:enter)         # special key
KeyEvent(:ctrl, 'a')     # control key
```

Special keys: `:enter`, `:escape`, `:backspace`, `:tab`, `:up`, `:down`, `:left`, `:right`, `:home`, `:end_key`, `:pageup`, `:pagedown`, `:delete`.

Fields: `evt.key :: Symbol`, `evt.char :: Char`.

### MouseEvent

Mouse clicks, scrolls, drags. Handle in `update!(model, evt::MouseEvent)`.

### ResizeEvent

Terminal resize. Handle in `update!(model, evt::ResizeEvent)`.

---

## Graphics API

Three rendering backends:

- **Canvas** — Braille dots (2×4 per cell)
- **BlockCanvas** — Quadrant blocks (2×2 per cell)
- **PixelImage** — Full pixel rendering (16×32 per cell, Kitty or sixel)

Vector drawing: lines, arcs, circles, shapes.

---

## Testing API

### TestBackend

```julia
tb = TestBackend(80, 24)
render_widget!(tb, widget)
render_widget!(tb, widget; rect=Rect(1, 1, 40, 10))
```

### Inspection

```julia
char_at(tb, x, y)       # character at position
row_text(tb, row)        # entire row as string
find_text(tb, "text")    # → (x=col, y=row) or nothing
style_at(tb, x, y)       # → Style
```

### Key Simulation

```julia
KeyEvent('a')
KeyEvent(:enter)
KeyEvent(:ctrl, 'z')
handle_key!(widget, KeyEvent('x'))
```

### Test Organization

```
test/
├── runtests.jl
├── test_core.jl
├── test_layout.jl
├── test_widgets.jl
└── test_events.jl
```

Tips:
- Re-render after events (widgets update state on `handle_key!` but visual output changes after `render`)
- Set `focused=true` for interactive widgets
- Use `find_text` for loose assertions
- `handle_key!` returns `true` if consumed — test event delegation

---

## Recording API

```julia
# Live recording toggle: Ctrl+R during app
record_app(model; frames=120, path="demo.tach")
record_widget(widget, width, height; frames=60, path="widget.tach")
```

Native `.tach` format with Zstd compression. Export to SVG and GIF (GIF requires `FreeTypeAbstraction` + `ColorTypes`).

---

## Backgrounds

```julia
# Procedural animated backgrounds
DotWave   # undulating dot-matrix terrain
PhyloTree # animated branching structures
Cladogram # hierarchical tree visualizations
```

---

## Demos

The `demos/TachikomaDemos` package includes 25+ interactive demos:

```julia
using Pkg
Pkg.activate("demos/TachikomaDemos")
Pkg.instantiate()

using TachikomaDemos
launcher()  # interactive menu
# Or individual: dashboard(), snake(), life(), sysmon(), chart_demo(), form_demo()
```
