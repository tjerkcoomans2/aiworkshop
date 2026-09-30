# ABL Business Entity Architecture Pattern

> Condensed version of the ProjectGengar documentation.

## Overview

The Business Entity pattern separates UI logic from database access in OpenEdge ABL applications through three layers:

| Layer | Responsibility | Rules |
|-------|----------------|-------|
| UI (windows/forms) | User interaction and presentation | Never accesses database tables directly; calls Business Entity methods with datasets |
| Business Entity | Data access, business rules, validation | Inherits `OpenEdge.BusinessLogic.BusinessEntity`; obtained through `EntityFactory` |
| Database | Persistent storage | Only accessed through data-sources attached to business entities |

## Key Components

### EntityFactory (singleton)

Central point for obtaining business entity instances (lazy initialization, one instance per entity).

```abl
CLASS business.EntityFactory USE-WIDGET-POOL:
    VAR PRIVATE STATIC EntityFactory objInstance.
    VAR PRIVATE CustomerEntity objCustomerEntityInstance.

    CONSTRUCTOR PRIVATE EntityFactory():
    END CONSTRUCTOR.

    METHOD PUBLIC STATIC EntityFactory GetInstance():
        IF objInstance = ? THEN
            objInstance = NEW EntityFactory().
        RETURN objInstance.
    END METHOD.

    METHOD PUBLIC CustomerEntity GetCustomerEntity():
        IF objCustomerEntityInstance = ? THEN
            objCustomerEntityInstance = NEW CustomerEntity().
        RETURN objCustomerEntityInstance.
    END METHOD.
END CLASS.
```

### Dataset definition (`.i` include)

```abl
DEFINE TEMP-TABLE ttCustomer BEFORE-TABLE bttCustomer
    FIELD CustNum AS INTEGER INITIAL "0" LABEL "Cust Num"
    FIELD Name AS CHARACTER LABEL "Name"
    /* ... additional fields ... */
    INDEX CustNum IS PRIMARY UNIQUE CustNum ASCENDING.

DEFINE DATASET dsCustomer FOR ttCustomer.
```

- `BEFORE-TABLE` enables change tracking for updates
- The primary index mirrors the database primary key
- Shared through an include file so entity and UI use the same definition

### Business Entity class

```abl
CLASS business.CustomerEntity INHERITS BusinessEntity USE-WIDGET-POOL:

    {business/CustomerDataset.i}

    DEFINE DATA-SOURCE srcCustomer FOR Customer.

    CONSTRUCTOR PUBLIC CustomerEntity():
        SUPER(DATASET dsCustomer:HANDLE).

        VAR HANDLE[1] hDataSourceArray = DATA-SOURCE srcCustomer:HANDLE.
        VAR CHARACTER[1] cSkipListArray = [""].

        THIS-OBJECT:ProDataSource = hDataSourceArray.
        THIS-OBJECT:SkipList = cSkipListArray.
    END CONSTRUCTOR.

END CLASS.
```

Requirements: pass the dataset handle to `SUPER()`, assign one data-source per temp-table to `ProDataSource`, and a `SkipList` array of the same length.

## CRUD Operations

| Operation | Entity method | Parameter mode |
|-----------|---------------|----------------|
| Read | `THIS-OBJECT:ReadData(cFilter)` | `OUTPUT DATASET` (no `BY-REFERENCE`) |
| Create | `THIS-OBJECT:CreateData(DATASET ds BY-REFERENCE)` | `INPUT-OUTPUT DATASET` |
| Update | `THIS-OBJECT:UpdateData(DATASET ds BY-REFERENCE)` | `INPUT-OUTPUT DATASET` |
| Delete | `THIS-OBJECT:DeleteData(DATASET ds BY-REFERENCE)` | `INPUT-OUTPUT DATASET` |

### Read

```abl
METHOD PUBLIC LOGICAL GetCustomerByNumber(INPUT ipiCustNum AS INTEGER,
                                          OUTPUT DATASET dsCustomer):
    THIS-OBJECT:ReadData("WHERE Customer.CustNum = " + STRING(ipiCustNum)).
    RETURN CAN-FIND(FIRST ttCustomer).
END METHOD.
```

### Update from the UI

```abl
lFound = objCustomerEntity:GetCustomerByNumber(iCustNum, OUTPUT DATASET dsCustomer).

IF lFound THEN DO:
    FIND FIRST ttCustomer.
    TEMP-TABLE ttCustomer:TRACKING-CHANGES = TRUE.
    ttCustomer.Name = "Updated Name".

    isValid = objCustomerEntity:ValidateCustomer(INPUT-OUTPUT DATASET dsCustomer BY-REFERENCE,
                                                 OUTPUT cErrorMessage).
    IF isValid THEN
        objCustomerEntity:UpdateCustomer(INPUT-OUTPUT DATASET dsCustomer BY-REFERENCE).
    ELSE
        MESSAGE cErrorMessage VIEW-AS ALERT-BOX.
END.
```

Steps: fetch with `OUTPUT DATASET`, enable `TRACKING-CHANGES`, modify, validate, save with `BY-REFERENCE`. Deletes follow the same flow with `DELETE ttCustomer.` and `DeleteCustomer`.

## Validation

Put validation in the entity (e.g. `ValidateCustomer(INPUT-OUTPUT DATASET dsCustomer, OUTPUT errorMessage AS CHARACTER)`), return a specific error message, and always validate before create/update.

## Multi-Table Entities

Define one data-source per table, size the `ProDataSource`/`SkipList` arrays to the number of tables in dataset order, and relate the temp-tables with a `DATA-RELATION`:

```abl
DEFINE DATASET dsOrder FOR ttOrder, ttOrderLine
    DATA-RELATION OrderLines FOR ttOrder, ttOrderLine
        RELATION-FIELDS(OrderNum, OrderNum).
```

## Common Pitfalls

1. **`BY-REFERENCE` on `OUTPUT DATASET` for reads** - causes handle mismatches; use plain `OUTPUT DATASET`.
2. **Change tracking not enabled** - set `TEMP-TABLE tt:TRACKING-CHANGES = TRUE` before modifying, or updates are not detected.
3. **Data-source not assigned** - defining a `DATA-SOURCE` is not enough; assign it to `ProDataSource`.
4. **Direct database access from the UI** - go through the business entity instead.
5. **No named buffers** - always access tables through an explicitly defined buffer:

```abl
DEFINE BUFFER bCustomer FOR Customer.

FOR EACH bCustomer WHERE bCustomer.Country = 'USA':
    /* ... */
END.
```

## Refactoring Legacy Code

1. Identify direct `FIND`/`FOR EACH` database access and validation logic in UI code
2. Create the dataset include (`business/<Entity>Dataset.i`)
3. Create the entity class (`business/<Entity>Entity.cls`)
4. Add a getter and cleanup for the entity to `EntityFactory`
5. Replace UI database access with entity calls
6. Move validation into the entity
7. Test incrementally, one UI component at a time

## References

- `src/business/CustomerEntity.cls`
- `src/business/EntityFactory.cls`
- `src/business/CustomerDataset.i`
- `src/CustomerWin.w`
