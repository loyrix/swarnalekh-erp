# SwarnaLekh Project Blueprint

## Source Of Truth

This blueprint is aligned to:

`/Users/satyamjaiswal/Downloads/Jewellery ERP System Flow (1).pdf`

No product plan in this repository should override that PDF.

## Product Goal

Build a jewellery ERP that is:

- Simple for staff
- Fast for billing
- Easy for inventory management
- Easy for mortgage / gold loan handling
- Clean and professional
- Mobile friendly
- Low training
- Fast enough for counter usage
- Scalable after the PDF-defined base is stable

## Active Modules

### 1. Login And Access

Purpose: secure access for shop admin and staff users.

Required:

- Username and password login
- Optional mobile number login
- Remember session
- Logout
- Role-based access

Roles:

- Admin: inventory, billing, mortgage, reports, settings, user management
- Staff: billing, inventory view, limited mortgage access

### 2. Main Dashboard

Purpose: quick overview of daily business operations.

Required summaries:

- Total gold stock
- Total silver stock
- Total inventory value
- Monthly revenue
- Pending mortgage interest
- Active loans
- Sold products
- Today's sales
- Total bills generated

Required quick actions:

- Add Stock
- New Bill
- Add Mortgage
- Search Product
- Search Customer

Optional charts:

- Monthly sales graph
- Gold stock trend
- Loan collection graph
- Daily billing summary

### 3. Inventory Management

Purpose: manage jewellery stock and make stock available for billing.

Required menu:

- Dashboard
- Add Stock
- View Inventory
- Sold Products
- Product Details
- Stock Reports

Inventory dashboard:

- Total gold weight
- Total silver weight
- Total diamond stock
- Total product count
- Low stock alerts
- Out of stock alerts
- High value products
- Unsold products

Inventory table columns:

- Product image
- Product name
- Category
- Design number
- Purity
- Gross weight
- Net weight
- Selling price
- Stock status
- Branch
- Actions

Add stock sections:

- Product details: product name, category, design number, purity, branch
- Weight details: gross weight, stone weight, net weight
- Price details: purchase price, selling price, making charges
- Upload image

Categories from PDF:

- Ring
- Necklace
- Chain
- Bangles
- Earrings
- Pendant
- Bracelet
- Coin

Purity options from PDF:

- 18K
- 22K
- 24K
- Silver 925

Statuses:

- Available
- Sold
- Reserved

Automatic inventory behavior:

- Calculate net weight
- Calculate final selling price
- Calculate making charges where inputs allow
- Reduce stock after billing
- Mark billed products as sold
- Move sold products to Sold Products

### 4. Mortgage / Gold Loan Management

Purpose: manage customer gold loans and interest collection.

Required menu:

- Dashboard
- Add Mortgage
- Active Loans
- Collect Interest
- Closed Loans
- Mortgage Reports

Mortgage dashboard:

- Active loans
- Closed loans
- Pending interest
- Total loan amount
- Overdue loans
- Today's collections

Add mortgage sections:

- Customer details: customer name, mobile number, address, Aadhaar number
- Gold details: ornament type, purity, gross weight, net weight
- Loan details: loan amount, interest rate, loan date

Extra customer verification:

- Aadhaar number
- PAN number
- Photo ID
- Customer photo

Loan calculations:

- Monthly interest
- Total payable amount
- Due date
- Pending balance

Interest collection:

- Open active loan
- Collect interest amount
- Generate payment receipt
- Update pending balance
- Save payment history
- Show next due date

Closing:

- Customer pays full amount
- Mark loan closed
- Move to closed loans
- Show customer name, loan amount, interest paid, closing date, loan status

### 5. Billing And Invoice Management

Purpose: generate jewellery invoices quickly and reduce inventory automatically.

Required menu:

- Dashboard
- New Bill
- Invoice History
- Sales Reports

Billing dashboard:

- Today's revenue
- Monthly revenue
- Total bills
- Average bill value
- Top selling products

New bill flow:

1. Enter customer details.
2. Search inventory.
3. Select product.
4. Auto-fill product data.
5. Calculate bill.
6. Select payment method.
7. Generate invoice.
8. Reduce inventory.

New bill sections:

- Customer details: customer name, mobile number
- Select products: search inventory, select product
- Bill table: product, weight, price, quantity, total
- Bill calculation: gold value, making charges, GST, final total
- Payment section: cash, UPI, card

Supported payment methods:

- Cash
- UPI
- Debit Card
- Credit Card
- Bank Transfer

Invoice features:

- Shop logo
- Invoice number
- Customer details
- Product details
- GST breakdown
- Payment method
- Optional QR code

Invoice history:

- Search by customer
- Search by date
- Search by invoice number
- Reprint invoice
- Download PDF
- Share invoice on WhatsApp
- Filter by date

Automatic billing behavior:

- Generate invoice number
- Save invoice history
- Calculate GST
- Reduce inventory
- Mark product sold
- Update dashboard

### 6. Reports

Reports exist only as PDF-defined operational summaries.

Inventory reports:

- Current stock
- Sold products
- Low stock

Billing reports:

- Daily sales
- Monthly sales
- GST

Mortgage reports:

- Active loans
- Interest collection
- Closed loans

### 7. Search And Filters

Search should be available everywhere.

Search by:

- Product name
- Design number
- Customer name
- Invoice number
- Mobile number

Filters:

- Date
- Category
- Branch
- Status

### 8. Responsive Design

The app must work on:

- Desktop
- Tablet
- Mobile devices

Mobile UI rules:

- Large buttons
- Touch-friendly forms
- Responsive tables
- Fast loading pages

## Explicitly Removed From Active Planning

These are not in the PDF and should not appear as current roadmap items:

- Schemes
- Ledger
- Subscription strategy
- Premium / Pro / Elite plans
- Standalone multilingual feature plan
- Offline sync roadmap
- Advanced CRM
- Super-admin workflow
- External rate provider workflow

They can return only if the PDF is revised or the user explicitly adds them to scope.
