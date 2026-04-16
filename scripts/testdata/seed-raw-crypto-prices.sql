-- CoinGecko price snapshots for BTC and ETH.
-- Multiple snapshots to test that the dbt model picks the latest price.

INSERT INTO raw.coingecko_prices (_airbyte_raw_id, _airbyte_extracted_at, id, symbol, current_price, last_updated) VALUES
('price-001', '2026-03-28 09:00:00', 'bitcoin', 'btc', 67500.00, '2026-03-28 09:00:00'),
('price-002', '2026-03-28 09:00:00', 'ethereum', 'eth', 3450.00, '2026-03-28 09:00:00'),
('price-003', '2026-03-28 10:00:00', 'bitcoin', 'btc', 67800.00, '2026-03-28 10:00:00'),
('price-004', '2026-03-28 10:00:00', 'ethereum', 'eth', 3475.00, '2026-03-28 10:00:00'),
-- Latest prices (should be picked by the dbt model)
('price-005', '2026-03-28 11:00:00', 'bitcoin', 'btc', 68100.00, '2026-03-28 11:00:00'),
('price-006', '2026-03-28 11:00:00', 'ethereum', 'eth', 3510.00, '2026-03-28 11:00:00');
