-- Synthetic orders matching the DocumentDB document structure.
-- Includes orders in USD, EUR, BTC, and ETH to test crypto enrichment.
-- Includes a deliberate duplicate (ORD-00001 appears twice) to test deduplication.

INSERT INTO raw.orders (_airbyte_raw_id, _airbyte_extracted_at, orderId, customerId, status, currency, items, shipping, createdAt) VALUES
('raw-001', '2026-03-28 10:00:00', 'ORD-00001', 'CUST-0001', 'completed', 'USD',
 '[{"sku":"WIDGET-A","productName":"Standard Widget","qty":3,"unitPrice":29.99},{"sku":"CABLE-USB","productName":"USB-C Cable","qty":1,"unitPrice":12.99}]',
 '{"country":"US","method":"standard"}', '2026-03-28 09:15:00'),

('raw-002', '2026-03-28 10:00:00', 'ORD-00002', 'CUST-0002', 'completed', 'EUR',
 '[{"sku":"GADGET-X","productName":"Smart Gadget","qty":1,"unitPrice":149.00}]',
 '{"country":"NL","method":"express"}', '2026-03-28 08:30:00'),

('raw-003', '2026-03-28 10:00:00', 'ORD-00003', 'CUST-0003', 'completed', 'BTC',
 '[{"sku":"GADGET-Y","productName":"Pro Gadget","qty":2,"unitPrice":0.0035}]',
 '{"country":"DE","method":"standard"}', '2026-03-27 14:00:00'),

('raw-004', '2026-03-28 10:00:00', 'ORD-00004', 'CUST-0001', 'pending', 'USD',
 '[{"sku":"SCREEN-GRD","productName":"Screen Guard","qty":5,"unitPrice":9.99}]',
 '{"country":"US","method":"overnight"}', '2026-03-28 11:00:00'),

('raw-005', '2026-03-28 10:00:00', 'ORD-00005', 'CUST-0004', 'completed', 'ETH',
 '[{"sku":"WIDGET-B","productName":"Premium Widget","qty":1,"unitPrice":0.018}]',
 '{"country":"GB","method":"express"}', '2026-03-26 16:45:00'),

('raw-006', '2026-03-28 10:00:00', 'ORD-00006', 'CUST-0002', 'cancelled', 'GBP',
 '[{"sku":"ADAPTER-PWR","productName":"Power Adapter","qty":2,"unitPrice":24.99}]',
 '{"country":"NL","method":"standard"}', '2026-03-27 09:00:00'),

('raw-007', '2026-03-28 10:00:00', 'ORD-00007', 'CUST-0005', 'completed', 'USD',
 '[{"sku":"WIDGET-A","productName":"Standard Widget","qty":1,"unitPrice":29.99},{"sku":"CASE-PROT","productName":"Protective Case","qty":1,"unitPrice":34.99}]',
 '{"country":"JP","method":"express"}', '2026-03-25 11:30:00'),

('raw-008', '2026-03-28 10:00:00', 'ORD-00008', 'CUST-0003', 'completed', 'EUR',
 '[{"sku":"CABLE-USB","productName":"USB-C Cable","qty":3,"unitPrice":12.99}]',
 '{"country":"DE","method":"standard"}', '2026-03-28 07:15:00'),

-- Deliberate duplicate of ORD-00001 with a later extraction timestamp.
-- The dbt dedup layer should keep only this newer version.
('raw-009', '2026-03-28 11:00:00', 'ORD-00001', 'CUST-0001', 'completed', 'USD',
 '[{"sku":"WIDGET-A","productName":"Standard Widget","qty":3,"unitPrice":29.99},{"sku":"CABLE-USB","productName":"USB-C Cable","qty":1,"unitPrice":12.99}]',
 '{"country":"US","method":"standard"}', '2026-03-28 09:15:00'),

('raw-010', '2026-03-28 10:00:00', 'ORD-00009', 'CUST-0006', 'completed', 'BTC',
 '[{"sku":"GADGET-X","productName":"Smart Gadget","qty":1,"unitPrice":0.0017}]',
 '{"country":"AU","method":"standard"}', '2026-03-26 20:00:00');
