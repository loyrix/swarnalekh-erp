# SwarnaLekh System Flow Plan

## Source Of Truth

This flow follows:

`/Users/satyamjaiswal/Downloads/Jewellery ERP System Flow (1).pdf`

## Main Access Flow

```text
Login System
  -> Dashboard
       -> Inventory
       -> Mortgage
       -> Billing
```

## Login Flow

Required:

- Username and password login
- Optional mobile number login
- Role-based access
- Remember session
- Logout

Admin access:

- Inventory
- Billing
- Mortgage
- Reports
- Settings
- User management

Staff access:

- Billing
- Inventory view
- Limited mortgage access

## Dashboard Flow

Dashboard should show:

- Total gold stock
- Total silver stock
- Monthly sales
- Pending mortgage interest
- Active loans
- Sold products

Quick actions:

- Add Stock
- New Bill
- Add Mortgage
- Search Product
- Search Customer

## Inventory Flow

```text
Add New Product
  -> Save Product
  -> Product Visible In Inventory
       -> Used In Billing
            -> Stock Reduced
       -> Available In Inventory
```

Inventory menu:

- Dashboard
- Add Stock
- View Inventory
- Sold Products
- Product Details
- Stock Reports

## Mortgage Flow

```text
Add Customer
  -> Add Gold Details
  -> Create Loan
  -> Loan Added To Active Loans
       -> Collect Interest
       -> Close Loan
```

Mortgage menu:

- Dashboard
- Add Mortgage
- Active Loans
- Collect Interest
- Closed Loans
- Mortgage Reports

## Billing Flow

```text
Select Customer
  -> Select Product
  -> Calculate Bill
  -> Generate Invoice
  -> Reduce Inventory
  -> Save Invoice History
```

Billing menu:

- Dashboard
- New Bill
- Invoice History
- Sales Reports

## Automatic System Actions

After bill generation:

- Invoice generated
- Inventory reduced
- Product marked sold
- Invoice saved
- Dashboard updated

Inventory automation:

- Reduce stock automatically
- Mark sold products
- Update stock reports

Billing automation:

- Generate invoice number
- Save invoice history
- Calculate GST automatically

Mortgage automation:

- Calculate interest
- Update pending balance
- Generate payment receipts

## Search And Filters

Search by:

- Product name
- Design number
- Customer name
- Invoice number
- Mobile number

Filter by:

- Date
- Category
- Branch
- Status
