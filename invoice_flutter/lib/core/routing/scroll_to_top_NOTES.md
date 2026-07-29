/// Port of `src/ScrollToTop.js`.
///
/// The original called `window.scrollTo(0, 0)` on every route change - a
/// web-only concept. Flutter's `Scaffold`/`ListView` each manage their own
/// scroll position per-route already (a fresh widget subtree per route
/// naturally starts scrolled to the top), so there is no equivalent
/// component to build here. Left as a doc-only stub so this behavior isn't
/// silently lost from the checklist - see CONVERSION_STATUS.md.
