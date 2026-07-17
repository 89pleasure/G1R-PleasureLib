# Settings UI investigation log

This file is the persistent source of truth for PleasureLib's custom Gothic 1
Remake settings page. Read it before changing the settings navigation code.

## Confirmed native structure

- `W_SettingsMain` contains seven native page buttons in `m_PageButtons`.
- `W_SettingsPage_Test` already exists as an additional child of
  `WidgetSwitcher_Pages`, but Gothic does not create a button for it.
- The test page is a `CommonActivatableWidget` and therefore requires
  `ActivateWidget()`/`DeactivateWidget()`, not only
  `WidgetSwitcher:SetActiveWidget()`.
- The custom bool setting, row, visible widget, and toggle have all reported
  `IsAvailable=true`, `IsSupported=true`, and `GetIsEnabled=true`. Their object
  references also match. The grey state is therefore a page/input-lifecycle
  issue, not an availability or binding issue.
- Gothic's `ButtonWidget` is not interactable without a click delegate even
  after `SetIsEnabled(true)`.

## Approaches that must not be repeated

| Approach | Result |
| --- | --- |
| Write the custom button into `SettingsMainWidget.m_PageButtons` | Native UE4SS access violation during settings construction. |
| Rebuild/clear Gothic's native page-button list | Native references and delegates become invalid; settings crash. |
| Bind `m_OnClickedBP:Add(...)` while the custom widget is being created | Cold-start race; sometimes works, sometimes the binding disappears, and some runs crash. |
| Combine a custom delegate with a global `ButtonWidget:OnClicked` hook | Native crash. |
| Bind from global `W_SettingsPageButton:OnMouseEnter` or `OnAddedToFocusPath` hooks | Hooks affect every native settings button and caused startup/settings crashes. |
| Hook `ButtonWidget:Click` without making the widget interactable | The native click pipeline is never entered. This is not a solution on its own. |
| Override `SettingsPageWidget:GetDisplayName()` for the test page | `CreatePageButtons` does not call this function for the filtered test page. |
| Write `m_DisplayName` on the live test page from the `W_SettingsMain:Construct` pre-hook | Reproducible allocator corruption while opening Settings. Do not mutate the page's `FText` during `Construct`. |
| Inject settings into the vanilla Game page | Previously caused duplicate/reordered rows across reinitialization. Do not return to it as an implicit fallback. |
| Use UE4SS `MulticastDelegateProperty:Add(target, function)` | The installed UE4SS commit `c2ac246447a8bcd92541070cb474044e7a2bbbe6` incorrectly reads both arguments from Lua stack index 1 in `LuaXDelegateProperty.cpp`. This creates invalid bindings and explains the intermittent crashes. |

## Known stable pieces

- Creating one `W_SettingsPageButton_C` with `WidgetBlueprintLibrary:Create` and
  attaching it only to `VerticalBox_PageButtons` is safe.
- Finding the test page after `SettingsMainWidget:CreatePageButtons`,
  `FocusActiveButton`, or the active-index callback is safe and idempotent.
- Injecting the setting into the existing test page is stable and deduplicated.
- Version `0.4.9` used a global left-mouse `RegisterKeyBind` plus
  `button:IsHovered()`. It opened the Mods page in one historical run, but the
  exact route failed to reproduce in `0.4.33`: the key callback ran while
  `IsHovered()` never identified the visible custom button. Treat the original
  result as a one-run success, not as a viable implementation.
- Version `0.4.19` did not use mouse routing. It used the custom button
  delegate and concrete `OnActivated` hook plus availability overrides. One
  restart activated the page and another did not; the bool remained grey.

## Abandoned experiment: geometry hit testing

Version `0.4.30` keeps the visible Mods entry delegate-free. On a global left
mouse press it uses only native read-only geometry APIs:

1. `WidgetLayoutLibrary:GetMousePositionOnPlatform()`
2. `button:GetCachedGeometry()`
3. `SlateBlueprintLibrary:IsUnderLocation(geometry, mousePosition)`

Unlike `IsHovered()`, this test does not depend on the widget being considered
interactable by Gothic. A hit activates the existing test page through
`SetActiveWidget()` followed by `ActivateWidget()`.

Do not add another delegate or button hook while evaluating this experiment.

### Result from 0.4.30

- The global left-mouse callback fired.
- The stored Mods button was found.
- `button:IsRendered()` returned `false` even though the entry was visibly
  present in the menu.
- Version 0.4.30 incorrectly used `IsRendered()` as a prerequisite and thus
  never called `IsUnderLocation()`.

`IsRendered()` must not be used as a gate for this custom delegate-free widget.
Version `0.4.31` executes the geometry test unconditionally and logs both
values independently.

### Result from 0.4.31

- The global left-mouse callback fired.
- The stored Mods button reported `IsRendered=true`.
- `IsUnderLocation(cachedGeometry, platformMousePosition)` returned `false`.
- The first measured click happened shortly before Gothic logged
  `Asset loaded`, so one measurement is insufficient to distinguish stale
  cached geometry from a desktop/viewport coordinate-space mismatch.

Version `0.4.32` added coordinate diagnostics. The user rejected the geometry
route as unnecessarily hacky before it was pursued further. Do not return to
manual geometry hit testing unless explicitly requested.

## Native `CreatePageButtons` analysis

The exact shipped `G1R-Win64-Shipping.exe` implementation was inspected at
RVA `0x5C64760`. `SettingsMainWidget::CreatePageButtons` iterates every child
of the supplied page switcher, verifies that it is a `SettingsPageWidget`, and
then calls the function at RVA `0x30EA390`. The latter reads `UWidget` offset
`0xD9`, mask `0x04`, exactly matching the dumped `bIsEnabled` property and its
`GetIsEnabled()` function. A page is skipped when this call returns false.

This explains the native structure: the switcher contains eight settings
pages, but Gothic creates only seven buttons because `W_SettingsPage_Test` is
disabled. The correct native integration point is therefore the
`CreatePageButtons` pre-hook: enable the already constructed test page before
the original function iterates the switcher. Gothic can then create, bind,
index, focus, and activate the eighth button itself.

## Current implementation

Version `0.4.34` proved that mutating the page prototype from
`NotifyOnNewObject(W_SettingsPage_Test_C)` is unsafe. Opening Settings crashed
before `CreatePageButtons` ran with `EXCEPTION_ACCESS_VIOLATION` in UE4SS; its
stack hash `FF163EF78090254FDA6D177D37D2C8A245D16F51` matches four earlier
Settings-opening crashes. Do not call widget functions or assign `FText` from
that construction notification.

Version `0.4.35` enables only the live `W_SettingsPage_Test` immediately before
Gothic's native `CreatePageButtons` runs. The pre-hook changes only
`bIsEnabled` through `SetIsEnabled(true)`. After the native function returns,
the live page and its native button receive the Mods display name and the
registered settings are injected. No page-prototype mutation, custom button,
delegate, array mutation, mouse route, geometry hit test, or manual page
activation remains.

The first `0.4.35` test did not crash but produced only the seven vanilla
buttons. The hook ignored `CreatePageButtons`' `_PagesSwitcher` parameter and
read `W_SettingsMain.WidgetSwitcher_Pages` instead. That bound property is not
reliable while the widget is still being constructed. Version `0.4.36` uses
the supplied native switcher parameter in the pre-hook and retains the live
switcher for post-hook finalization. Temporary diagnostics log page count,
the Test page's enabled state before/after the pre-hook, and the resulting
native button count.

The `0.4.36` log proved that the native parameter is correct: the supplied
switcher contained nine pages and the Test page was found. However,
`SetIsEnabled(true)` left both its reported enabled state and Gothic's native
button count unchanged (`false`, seven buttons). Version `0.4.37` therefore
sets and verifies the reflected `UWidget.bIsEnabled` bit directly on the live
page. This is the exact offset/mask read by `CreatePageButtons` (`0xD9`,
`0x04`); no CDO, prototype, `FText`, array, or delegate is touched.

The `0.4.37` result confirmed that the raw bit is the correct native gate. The
first menu construction still produced seven buttons, but the next
construction appended eight (`7 -> 15`) and displayed the native Test page.
`GetIsEnabled()` remained false even while `bIsEnabled` was true, so it must
not be used to map the resulting native button. Version `0.4.38` seeds the raw
bit from the already-safe `W_SettingsMain` notification before the first
`CreatePageButtons` call and maps the newly appended button as
`button_count_before + enabled_page_ordinal`. Existing native arrays remain
untouched. The unused Test rows are collapsed rather than detached because
native `Reinitialize` reattaches registered rows.

With every other Lua mod disabled, `0.4.38` crashed while opening Settings.
The crash happened after `CreatePageButtons` produced only seven buttons but
before finalization logged success, and its hash was again
`FF163EF78090254FDA6D177D37D2C8A245D16F51`. The early Main notification had
not seeded the page (`rawBefore=false`), while the post-hook still mapped the
first vanilla button as the absent Test button and began unsafe construction-
time `FText` work. Version `0.4.39` never finalizes unless the number of newly
appended buttons exactly matches the number of raw-enabled pages. It performs
no page `FText` assignment and no content injection during construction. A
minimal page notification writes only `bIsEnabled`; button naming happens only
after a complete native batch, while title and content updates wait for the
page's native activation event.

With every other Lua mod still disabled, `0.4.39` opened Settings without a
crash and displayed only the Extended Item Tooltips setting on the native Test
page. The pre-hook observed nine switcher pages and eight raw-enabled pages,
while Gothic appended nine native buttons. The exact `added == expected` guard
therefore prevented only the final button/title rename; the page itself and its
content lifecycle were stable. Version `0.4.40` accepts
`added >= expected` as proof of a complete native batch. This accepts the
observed stable `9 >= 8` build while continuing to reject the known unsafe
partial `7 < 8` build from `0.4.38`.

Both `0.4.39` and `0.4.40` reproduced a second, distinct crash when leaving the
open Test settings page with Back/ESC. The crash hash is
`2150B2B6515A1CFBFA12F27131A41DA3DE5DA243`, with an access violation reading
`0x3D8` from a null pointer at game RVA `0x5C66653`. Disassembly proves that
the native function iterates `SettingsMainWidget.m_PageButtons` (offset
`0x460`) and reads `SettingsPageButtonWidget.m_IsActive` (offset `0x3D8`)
without a null check. The screenshot contains eight visible buttons while the
post-hook reports nine array entries. This is a native navigation/focus crash,
not evidence of an INI persistence failure. Version `0.4.41` adds read-only
diagnostics for the actual TArray elements, panel children, switcher pages, and
the beginning/end of the mod commit hook. Do not mutate or rebuild the array
until these diagnostics identify the exact invalid slot and its lifecycle.

The `0.4.41` diagnostics identified the exact cause. Immediately after the
native build, `m_PageButtons` contained slot 1 as null followed by eight valid
native buttons, while the switcher contained one non-page `VerticalBox` and
eight real settings pages. PleasureLib itself created the null slot in the
pre-hook: `settings_page_button_for` calculated the target ordinal but then
also indexed the still-empty `m_PageButtons[1]`. This UE4SS version resizes a
`TArray` when an out-of-range index is accessed. Gothic subsequently appended
its eight valid buttons, resulting in `null + 8 = 9`; Back/ESC later crashed
when native `FocusActiveButton` dereferenced the null entry. Version `0.4.42`
separates ordinal calculation from button resolution, so the pre-hook performs
no TArray indexing. Button lookup happens only after Gothic has completed the
native batch.

The first `0.4.42` reopen retained eight visible buttons but appended a second
eight-button batch to the reused `SettingsMainWidget.m_PageButtons` array. The
visible panel contained only the new batch, while the old button UObjects
remained valid. PleasureLib therefore kept renaming the cached, hidden Test
button from the first batch; the main title showed Mods but the new visible
button reverted to Test. Version `0.4.43` always resolves and stores the button
from the explicitly supplied new batch base after `CreatePageButtons`. Fallback
finalizers without a batch base may continue reusing the current cached button.

Version `0.4.44` removes the temporary binding, TArray, switcher, page-build,
and commit diagnostics used to prove the `0.4.41` through `0.4.43` fixes. The
defensive batch-size guard, out-of-range protection, current-batch remapping,
normal debug-only messages, real error messages, and one-time success message
remain.

The first full-mod integration run with `0.4.44` showed the native Test rows
again and duplicated the Extended Item Tooltips row during category changes.
This run initially also re-enabled seven other Lua mods, so it changed two
variables at once. There was no second registration of the same PleasureLib
setting ID in the log or source scan. The runtime was therefore rolled back to
the complete `0.4.43` state, including its read-only diagnostics, while the
normal mod set remained active.

The controlled result is stable across multiple complete game restarts:
`0.4.43` displays only the registered Extended Item Tooltips setting, does not
duplicate it during category changes, retains the Mods label after reopening,
and persists the toggle correctly. Therefore the abandoned `0.4.44` cleanup
changed runtime behavior despite removing only code believed to be diagnostic.
The exact timing, object-lifetime, or callback-order dependency has not been
isolated. Keep the complete `0.4.43` implementation as the known-good baseline
and do not repeat that cleanup as one combined change.

As a first isolated cleanup experiment, version `0.4.45` removed only the
`Native Mods settings commit begin/end` log writes while retaining every
diagnostic read, hook, cache, and callback. One cold start displayed all four
native Test settings again; the following restart with the same build did not.
This A/B result is nondeterministic and does not establish the removed logs as
the cause. It instead confirms an unresolved lifecycle/timing race that can
produce different results from identical code. Keep `0.4.43` as the known-good
baseline for now, but treat the log-removal experiment as inconclusive rather
than as a failed functional change.

Version `0.4.46` tested the hypothesis that `Reinitialize` replaces the native
Test row instances after the first initialization. On every injection it
rescanned `m_SettingsRowWidgets`, protected the claimed native Bool row and all
PleasureLib bindings, and collapsed every remaining registered row. The four
native Test entries were immediately visible on both of two complete game
starts. Reject this registry-rescan approach and do not repeat it; the complete
Lua implementation was restored byte-for-byte to `0.4.43`.

## Resolved lifecycle race and current baseline

This section supersedes the earlier instructions to keep `0.4.43` as the
known-good baseline. Those instructions remain above as historical context for
the investigation.

Diagnostics in versions `0.4.47` through `0.4.49` identified the actual
nondeterministic state. In affected cold starts, the live Test page and its
five registered rows remained valid and readable through
`m_SettingsRowWidgets`, while inherited UMG calls such as `GetParent()`,
`GetContent()`, `GetChildrenCount()`, and `GetChildAt()` returned `nil`.
PleasureLib treated those unavailable structural reads as proof that the
custom Bool row had been detached, discarded its still-valid binding, and
created another row on every activation. This caused both the duplicates and
the apparent timing dependency.

The stable implementation is based on the following rules:

- `NotifyOnNewObject(W_SettingsPage_Test_C)` excludes `Default__` objects and
  writes only the live page's raw `bIsEnabled` bit. It must not call widget
  functions, touch `FText`, or inject content during construction.
- Blueprint-only `W_SettingsMain:Construct` and `PreConstruct` hooks execute
  after their Blueprint body in this UE4SS build. They are too late to seed the
  page before the `CreatePageButtons` call inside that body and must not be
  treated as native pre-hooks.
- The `CreatePageButtons` pre-hook uses its supplied switcher parameter and
  enables the Test page before Gothic builds the native button batch.
- The pre-hook calculates the target ordinal without indexing the still-empty
  `m_PageButtons` array. Finalization occurs only after the post-hook proves
  that the complete expected native batch was appended.
- A `nil` result from inherited panel, parent, or content functions means
  "reflection state unavailable", not "empty" or "detached".
- The current page registry, row-to-setting link, and row/widget setting links
  are authoritative while structural UMG calls are unavailable. A binding
  with intact registry links is retained. An ambiguous attachment is deferred;
  it is never discarded merely because a structural call returned `nil`.
- The native Int, Float, and two Enum Test rows are identified from the page
  registry. They are collapsed without removing them because native
  `Reinitialize` owns and restores the registered rows.
- Collapsing uses the reflected native UFunction
  `/Script/UMG.Widget:SetVisibility` with the row as its explicit context.
  This bypasses the inconsistent inherited member lookup and synchronizes the
  live Slate widget; a raw `Visibility` property write alone may not do so
  until the settings screen is rebuilt.
- Reordering and reattachment are skipped when panel structure cannot be read.
  No operation may interpret an unavailable child count as zero.

Version `0.4.56` established the raw-only construction seed. Version `0.4.57`
added registry-authoritative binding retention and eliminated duplicate custom
rows. Version `0.4.58` added the reflected `SetVisibility` call, which hid all
native Test rows on the first settings entry rather than only after reopening
the screen.

Version `0.4.58` passed six complete cold-start tests. Versions `0.4.59`
through `0.4.67` then removed the temporary lifecycle, binding, visibility,
navigation, and page-build diagnostics in isolated steps. Every step passed
three complete cold starts, including category changes, reopening Settings,
and a final toggle persistence test. Commit `5416f6f` preserves the fully
instrumented stable reference; commit `e53c0c7` is the cleaned `0.4.67`
baseline.

The validation above covers complete game starts. UE4SS hot reload can leave
old hooks, page state, or previously injected rows alive and is not part of the
stability guarantee for this integration.
