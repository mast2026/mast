Supabase CSV import helpers

Generated files:

- members_import.csv

Import order:

1. Run setup_v1.sql in the new Supabase SQL Editor.
2. Open Table Editor.
3. Select members.
4. Click Insert.
5. Choose Import data from CSV.
6. Upload members_import.csv.
7. Confirm columns are mapped as:
   - name
   - gi
   - school
   - major
   - email
8. Click Import data.

The email column is intentionally empty because email is nullable.
