-- Discover & Wishlist write path (this feature's Module 3): un-saving a
-- place or a saved-alone county deletes its `wishlist_items` row --
-- `SupabaseDiscoverRepository.toggleSavedPlace`/`toggleSavedCounty`. The
-- table's original migration (20260902144307) added select/insert/update
-- policies but no delete one, so a client-issued delete would have
-- silently matched zero rows under RLS (no error, no effect) rather than
-- actually removing anything -- caught while wiring the write path, not
-- yet exercised by any shipped code before this.
create policy "Users can delete their own wishlist items"
  on public.wishlist_items
  for delete
  to authenticated
  using (auth.uid() = user_id);
