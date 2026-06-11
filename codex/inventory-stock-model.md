# Inventory Stock Model

## Source Of Truth

This model follows:

`/Users/satyamjaiswal/Downloads/Jewellery ERP System Flow (1).pdf`

## Core Statuses

- `available`
- `sold`
- `reserved`

## Required Product Fields

- Product image
- Product name
- Product code
- Design number
- Category
- Purity
- Branch
- Gross weight
- Stone weight
- Net weight
- Purchase price
- Selling price
- Making charges
- GST
- Stock status

## Search Fields

- Product name
- Design number
- Customer name where sold
- Invoice number where sold
- Mobile number where sold

## Filter Fields

- Date
- Category
- Branch
- Status

## Status Transitions

```text
available -> sold
available -> reserved
reserved -> available
reserved -> sold
```

Rules:

- Billing can sell only available or explicitly selected reserved stock.
- Completed billing marks product as sold.
- Sold products should not appear as available inventory.
- Sold product history must show invoice and customer context.

## Calculated Fields

The system should automatically calculate where inputs are present:

- Net weight
- Making charges
- Final selling price

## Reports

Inventory reports from the PDF:

- Current stock report
- Sold products report
- Low stock report
