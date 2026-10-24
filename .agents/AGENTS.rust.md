# AGENTS.rust.md

This document helps AI agents work effectively in this codebase.

## Essential Commands

### Build
```bash
cargo build                    # Debug build
cargo build --release          # Release build
cargo build -p <crate>         # Build a single crate
```

### Run
```bash
cargo run --bin <binary> -- <args>
```

### Format
```bash
cargo +nightly fmt             # Always nightly: formatting settings rely on nightly
```

### Check/Lint
```bash
cargo +nightly clippy          # Always nightly: lint settings rely on nightly
```

### Test
```bash
cargo test
```

## Code Quality Principles

Follow **SOLID** (minus Liskov - SOID), **DRY**, and **KISS** principles:

- **No code smells** - Keep code clean and maintainable
- **No comments** - Code should be self-documenting via meaningful names
- **Self-documenting names** - No abbreviations unless universally known (e.g., `config` not `cfg`)
- **Fail fast** - Validate inputs early, avoid deep nesting (max 3-4 levels)
- **No magic numbers/strings** - Use named constants
- **Prefer composition over inheritance**
- **Keep methods small** - Ideally under 20 lines, single-purpose
- **Minimize dependencies** - Depend on abstractions, not concretions
- **No circular dependencies**
- **Prefer pure functions** where possible
- **Prefer immutability by default**
- **Make the code pleasing to look at** - Use consistent spacing, logical grouping and a clear visual flow, so the code reads easily at a glance. Dense, tightly packed code is a defect: follow the Vertical Spacing rules in Code Style & Conventions
- **Avoid trivial passthrough getters** - Prefer direct field access when no invariants/logic are enforced; keep fields private by default unless external access is required

## Rust-Specific Guidelines

- **Leverage ownership** - Avoid unnecessary cloning, use references where possible
- **Use iterators** - Prefer iterator chains over manual loops
- **No `unsafe`** - Unless absolutely necessary and well-documented why
- **Use `Result`/`Option`** - Never panic for expected error cases
- **Type safety** - Leverage the type system, avoid primitive obsession
- **Zero-cost abstractions** - Prefer generics, traits and iterators that compile down to the same code as the hand-written version; avoid runtime overhead (dynamic dispatch, boxing, extra allocations) unless it is genuinely needed
- **Suggest crates to simplify logic** - When a well-maintained crate outside the Essential Crates list would make the logic noticeably simpler or shorter than hand-rolling it, suggest it to the user before implementing; explain what it replaces and why it is worth the dependency

## Essential Crates

Reach for these before hand-rolling the same logic. They are pre-approved: no need to ask before using them. Add each one to the workspace root first, then reference it with `{ workspace = true }`.

### Application Foundation

| Crate       | Use it for                                                                    | Replaces                                  |
|-------------|-------------------------------------------------------------------------------|-------------------------------------------|
| `clap`      | CLI arguments and subcommands via derive macros (`Parser`, `Subcommand`)      | Manual `std::env::args` parsing           |
| `tokio`     | Async runtime, tasks, channels, timers, async IO                              | Hand-rolled threads for IO-bound work     |
| `eyre`      | Application-level error reporting                                             | `Box<dyn Error>`                          |
| `thiserror` | Library error type definitions                                                | Hand-written `Display`/`Error` impls      |
| `serde`     | Serialization and deserialization                                             | Manual parsing and formatting             |

### Type Ergonomics

| Crate            | Use it for                                                                               | Replaces                                      |
|------------------|------------------------------------------------------------------------------------------|-----------------------------------------------|
| `bon`            | Compile-time checked builders for structs and functions with many or optional parameters | Hand-written builders, long argument lists    |
| `better_defaults`| Deriving `Default` with custom per-field values                                          | Manual `impl Default` blocks                  |
| `strum`          | Deriving `Display`, `EnumString`, `EnumIter`, `AsRefStr`, `EnumCount` for enums          | Manual `match` blocks mapping enums to strings|

### Performance

| Crate    | Use it for                                                                  | Replaces                                       |
|----------|-----------------------------------------------------------------------------|------------------------------------------------|
| `rayon`  | Data parallelism for CPU-bound iterator chains (`par_iter`)                 | Hand-managed thread pools                      |
| `memchr` | Fast byte and substring searching in hot paths                              | Naive byte scanning and `str::find` in loops   |

### Usage Rules

- **`rayon` is for CPU-bound work only.** Never use it for IO or inside async code; use `tokio` tasks for that. Never call blocking `rayon` work directly on a `tokio` worker thread; hand it off with `tokio::task::spawn_blocking`.
- **`bon` over manual builders.** Do not write a `Builder` struct by hand; use `#[derive(Builder)]` or `#[builder]` on functions.
- **`strum` over manual enum conversions.** Do not write `match` blocks that only map an enum to a string or back.
- **`memchr` only on proven hot paths.** Do not use it for one-off searches; plain `str` methods are clearer.
- **`clap` derive only.** Do not use the builder API.

## Code Style & Conventions

- **Follow the Code Hierarchy** - Every file follows the ordering defined in the Code Hierarchy section below.
- **Use vertical spacing to show structure** - See the Vertical Spacing section below. Tightly packed function bodies with no blank lines are a style violation.

### Vertical Spacing

Separate logical blocks inside a function body with a single blank line. A reader should be able to see the phases of a function at a glance.

Add a blank line:

- After a guard or early return
- Between setup (bindings) and the action that uses them
- Before and after `match`, `if let`, `if`, `for`, and `while` blocks
- Before and after closures and `spawn` blocks
- Before the final return or tail expression when the function body has more than a few lines
- Between a block of state mutations and the next unrelated step (e.g. a trailing `cx.notify()`)

Keep together, with no blank line:

- A binding and the single statement that immediately consumes it
- A run of closely related assignments on the same object (e.g. `self.busy = true; self.failed = false;`)
- Consecutive short guards of the same kind
- A method call chain and its terminating call (e.g. `.detach()`)

Rules:

- Never use more than one consecutive blank line
- Never put a blank line directly after an opening brace or directly before a closing brace
- Functions of 3 lines or fewer need no internal spacing
- When unsure, add the blank line: spacing that is slightly too generous reads better than spacing that is too dense

Example of the expected style:

```rust
fn submit(&mut self, command: Result<Command, BookingError>, cx: &mut Context<Self>) {
    let command = match command {
        Ok(command) => command,
        Err(error) => {
            self.error(&error, cx);

            return;
        }
    };

    let operation_id = if let Command::Pay(payment) = &command {
        payment.operation_id.clone()
    } else {
        RecordId::generate()
    };

    let context = CommandContext {
        operation_id,
        actor: "Local operator".into(),
        at: now(),
        expected_revision: self.state.revision
    };

    self.request(
        Request::Apply {
            command: Box::new(command),
            context
        },
        &t!("ui.saved_on_this_device"),
        cx
    );
}

fn request(&mut self, request: Request, message: &str, cx: &mut Context<Self>) {
    if self.busy {
        return;
    }

    self.busy = true;
    self.failed = false;
    self.notice = t!("ui.saving");

    let client = self.client.clone();
    let message = message.to_owned();

    cx.spawn(async move |view, cx| {
        let result = client.execute(request).await;

        if let Err(error) = view.update(cx, |view, cx| {
            view.busy = false;

            match result {
                Ok(state) => {
                    view.state = state;

                    if let Ok(booking) = view.state.booking(&view.booking.id) {
                        view.booking.original = Some(booking.clone());
                    }

                    view.notice = message;
                    view.failed = false;
                    view.restore_armed = false;
                }
                Err(error) => {
                    view.notice = error.to_string();
                    view.failed = true;
                }
            }

            cx.notify();
        }) {
            eprintln!("Courtday view closed: {error}");
        }
    })
    .detach();

    cx.notify();
}
```

## Code Hierarchy

Every Rust file follows this order from top to bottom. Declarations always come first and behavior always comes last, so the shape of the file is visible at a glance.

1. **`mod` declarations** - Only in files that declare modules (`lib.rs`, `main.rs`, `mod.rs`)
2. **`use` imports** - Grouped Std → External → Crate (enforced by rustfmt)
3. **`pub use` re-exports**
4. **Constants and statics** - `const`, then `static`
5. **Type aliases**
6. **Enums**
7. **Structs**
8. **Traits**
9. **`impl` blocks** - Inherent `impl` for each type, in the same order the types were declared
10. **Trait `impl` blocks** - `impl Trait for Type`, after the inherent `impl` of the same type
11. **Free functions** - Always last, public before private

### Ordering Rules

- **Declarations before behavior.** No `impl` block or function may appear above any enum, struct, or trait declaration in the same file.
- **Functions are always last.** Free functions never sit between types or `impl` blocks.
- **Within each group, public before private.**
- **Within an `impl` block:** associated constants, then constructors (`new`, `from_*`, `with_*`), then public methods, then private methods.
- **`impl` blocks follow declaration order.** If `Alpha` is declared before `Beta`, then `impl Alpha` comes before `impl Beta`.
- **Derives and attributes stay attached** to their item and move with it.
- **No inline tests.** Tests live in `tests/` only, so there is no `#[cfg(test)]` block at the bottom of a file.

### Example

```rust
mod internal;

use std::path::PathBuf;

use eyre::Result;
use strum::Display;

use crate::config::Config;

pub use internal::PublicType;

const DEFAULT_RETRY_LIMIT: u32 = 3;

static DEFAULT_HOME: &str = "/var/lib/app";

type ShardId = u32;

#[derive(Debug, Display)]
pub enum Mode {
    Fast,
    Safe
}

pub struct Worker {
    mode: Mode,
    shard: ShardId
}

pub trait Runnable {
    fn run(&self) -> Result<()>;
}

impl Worker {
    pub fn new(mode: Mode, shard: ShardId) -> Self {
        Self { mode, shard }
    }

    pub fn shard(&self) -> ShardId {
        self.shard
    }

    fn retry_limit(&self) -> u32 {
        DEFAULT_RETRY_LIMIT
    }
}

impl Runnable for Worker {
    fn run(&self) -> Result<()> {
        process_shard(self.shard, self.retry_limit())
    }
}

pub fn process_shard(shard: ShardId, retry_limit: u32) -> Result<()> {
    resolve_home(shard).map(|_| ())
}

fn resolve_home(shard: ShardId) -> Result<PathBuf> {
    Ok(PathBuf::from(DEFAULT_HOME).join(shard.to_string()))
}
```

### Rustfmt Configuration
Located in `.rustfmt.toml`. The **nightly toolchain** must always be used for formatting and linting (`cargo +nightly fmt`, `cargo +nightly clippy`).

Key settings:
- `edition = "2024"`
- `max_width = 100`
- `trailing_comma = "Never"`
- `group_imports = "StdExternalCrate"`
- `imports_granularity = "Module"`
- `fn_single_line = true`

Rustfmt never adds blank lines between statements. Vertical spacing is the agent's responsibility; follow the Vertical Spacing section.

### Naming Conventions
- **Types**: PascalCase
- **Functions/Variables**: snake_case
- **Constants**: SCREAMING_SNAKE_CASE
- **Modules**: snake_case

### Import Style
Group imports: Std → External → Crate (enforced by rustfmt):
```rust
use std::path::PathBuf;

use eyre::Result;
use serde::{Deserialize, Serialize};

use crate::config::Config;
```

### Error Handling
- Use `eyre` only for CLI error reporting
- Use `thiserror` for library error definitions
- Use named error variants with fixed messages for known failures; avoid generic message variants
- Reserve `&'static str` for genuinely open-ended static context, not known failure cases
- Use `Box<str>` when an error must own runtime text; never store `String` just for display
- Wrap source errors with `#[error(transparent)]` and `#[from]` instead of formatting them
- Custom error types in `src/error.rs`
- Pattern: `Result<T, ErrorType>` or `eyre::Result<T>`
- **Never use panics for control flow** - Only for truly exceptional, unrecoverable cases
- **Fail fast** - Validate inputs at function entry, return errors early

### Async Patterns
- Uses `tokio` runtime
- Main entry: `#[tokio::main]`
- Async traits use `async_trait` (if needed)
- Prefer `?` for error propagation
- **Be mindful of allocations** in hot paths - avoid unnecessary clones in async contexts

## UI Architecture

Use MVVM + reactive state + unidirectional data flow, inspired by Jetpack Compose and SwiftUI, adapted to GPUI and Zopra.

- Prefer Zopra `view!` and `#[component]` for declarative layout and reusable presentation. Use native GPUI builders for behavior or APIs Zopra cannot express cleanly.
- Keep domain rules and persistence in the model. ViewModels own presentation state and async operations; views render state and forward user intent to named handlers.
- Follow one flow: user intent → owner handler → model operation → reactive state → rendered view. Do not mutate business state inside render functions or duplicate command logic across controls.
- Keep one source of truth. Reuse retained GPUI entities, subscriptions, and component state; use Zopra hooks for local state when they simplify ownership. Do not mirror the same value in hooks and entities.
- Keep focus, input handles, scroll position, and other window-local behavior in their narrowest owner. Preserve stable IDs, validation, keyboard behavior, and async lifetimes during refactors.
- Prefer small components and derived values over long builder chains, repeated layouts, generic reducers, or new architecture layers without a concrete need.

## Architecture Patterns

### Module Structure
Each crate follows this pattern:
```rust
// lib.rs
pub mod submodule;
pub use submodule::{Type, function};

// submodule/mod.rs
mod internal;
pub use internal::PublicType;
```

**`mod.rs` files contain exports only.** No logic of any kind inside them: only `mod` declarations and `pub use` re-exports.

**A module folder needs at least two Rust files, not counting `mod.rs`.** If a module would hold only one file, don't create a folder for it; put that file where it fits instead.

### Keep the Crate Root Clean
The root of `src/` should not fill up with `.rs` files.

- Essential files such as `lib.rs`, `main.rs` and `error.rs` belong in the root.
- Before adding any other file to the root (e.g. `network.rs`), ask:
  1. Does this really need to be in the root?
  2. Is there an existing module folder it fits into?
- Only add a root file when the answer to both is no. Root files are for when they are needed, not by default.

### CLI Structure
Uses `clap` derive macros:
```rust
#[derive(Parser)]
pub struct Args { ... }

#[derive(Subcommand)]
pub enum Commands { ... }
```

## Testing Approach

- **Do not write tests unless explicitly told to.**
- When told to write tests, they must live in a `tests/` directory at the root of the crate or workspace, not inline in source files.
- No explicit test framework beyond `cargo test`

## Agent Workflow

- **Do not write tests** unless explicitly told to
- Make minimal, focused changes and don't refactor unrelated code
- Read the surrounding code and follow existing patterns before writing new code
- Use plain `pub` for items shared across modules and omit `pub` for module-private items. Do not use `pub(crate)` or `pub(super)`
- Apply the Vertical Spacing rules to every function you write or edit; do a quick spacing check on your changes before running fmt
- Run `cargo +nightly fmt` and `cargo +nightly clippy` after changes; no separate `cargo check`
- Use Cargo's default workspace target directory: `target/debug` for debug artifacts and `target/release` for release artifacts. Do not create alternate build directories, pass `--target-dir`, or override `CARGO_TARGET_DIR`, including to bypass a Cargo lock
- Run only one agent-started Cargo command at a time, including format, lint, build, test, and run commands. Never launch Cargo commands in parallel tool calls or overlapping background jobs. Start the next command only after the previous command has finished
- **Do not cheat on clippy.** Fix the root cause of every warning properly. Never silence a lint with `#[allow(...)]`, `#![allow(...)]`, `#[expect(...)]`, `RUSTFLAGS` overrides, or by loosening lint settings in `Cargo.toml` or `clippy.toml`. If a warning truly cannot be fixed, stop and ask the user instead of suppressing it
- Use the Essential Crates freely; for any other crate, suggest it and wait for approval before adding it
- Don't edit `Cargo.lock` by hand
- Ask before making breaking public API changes
- Never run `git commit` or `git push` unless told to

## What to Avoid

- **God objects/classes** - Keep types focused and single-purpose
- **Primitive obsession** - Use strong types, not raw strings/ints
- **Feature envy** - Methods should operate on their own data
- **Dead code** - Remove unused code, don't leave commented-out blocks
- **Deep nesting** - Max 3-4 levels; use early returns
- **Empty error handlers** - Never ignore errors silently
- **Lint suppression** - Never use `#[allow]` (or similar) to hide clippy or compiler warnings; fix the underlying issue
- **Static dependencies** - Write testable code, use dependency injection
- **Premature optimization** - But don't write obviously inefficient code
- **Hand-rolled versions of Essential Crates** - Manual builders, enum string conversions, `Default` impls, and naive byte scanning in hot paths
- **Out-of-order files** - Functions above types, `impl` blocks above enums or structs, constants below `impl` blocks
- **Wall-of-code function bodies** - Statements packed together with no blank lines between logical phases

## Important Gotchas

1. **Fmt and clippy require nightly**: Always use `cargo +nightly fmt` and `cargo +nightly clippy`, never the stable versions

2. **Edition 2024**: Requires Rust 1.85+

3. **Workspace dependencies**: Always add new dependencies to the workspace root first, then reference them with `{ workspace = true }`
