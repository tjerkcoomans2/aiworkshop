/*------------------------------------------------------------------------
  File        : ItemEntity
  Purpose     : Business Entity for Item data access
  Syntax      : 
  Description : 
  Author(s)   : 
  Created     : Wed Sep 30 2026
  Notes       : 
----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING OpenEdge.BusinessLogic.BusinessEntity.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS business.ItemEntity INHERITS BusinessEntity USE-WIDGET-POOL:
    
    /* Maximum allowed value of the items on hand (OnHand * Price) */
    VAR PRIVATE DECIMAL MaxOnHandValue = 6000.
    
    /* Include dataset definition */
    {business/ItemDataset.i}
    
    /* Define data sources */
    DEFINE BUFFER bItem FOR Item.
    DEFINE DATA-SOURCE srcItem FOR bItem.
    
    /*------------------------------------------------------------------------------
     Purpose: Constructor for ItemEntity
     Notes:
    ------------------------------------------------------------------------------*/
    CONSTRUCTOR PUBLIC ItemEntity():
        SUPER(DATASET dsItem:HANDLE).

        VAR HANDLE[1] hDataSourceArray = DATA-SOURCE srcItem:HANDLE.
        VAR CHARACTER[1] cSkipListArray = [""].
        
        /* Data Source for each table in dataset */
        THIS-OBJECT:ProDataSource = hDataSourceArray.
        /* Skip-list entry for each table in dataset */
        THIS-OBJECT:SkipList = cSkipListArray.
    END CONSTRUCTOR.
    
    /*------------------------------------------------------------------------------
     Purpose: Get item by item number
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC LOGICAL GetItemByNumber(INPUT ipiItemNum AS INTEGER,
                                          OUTPUT DATASET dsItem):
        VAR CHARACTER cFilter.
        VAR LOGICAL lFound = FALSE.
        
        /* Build filter for item number */
        cFilter = "WHERE bItem.ItemNum = " + STRING(ipiItemNum).
        
        /* Read data using filter */
        THIS-OBJECT:ReadData(cFilter).
    
        /* Check if item was found */
        lFound = CAN-FIND(FIRST ttItem).
        
        RETURN lFound.
    END METHOD.
    
    /*------------------------------------------------------------------------------
     Purpose: Update item data
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID UpdateItem(INPUT-OUTPUT DATASET dsItem):
        /* Update data in database */
        THIS-OBJECT:UpdateData(DATASET dsItem BY-REFERENCE).
    END METHOD.
    
    /*------------------------------------------------------------------------------
     Purpose: Validate item data
     Notes: The price is mandatory and the total value of the items on hand
            may not exceed MaxOnHandValue
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC LOGICAL ValidateItem(INPUT-OUTPUT DATASET dsItem,
                                       OUTPUT errorMessage AS CHARACTER):
        VAR LOGICAL isValid = TRUE.
        VAR DECIMAL dTotal.
        
        /* Find the first item in the dataset */
        FIND FIRST ttItem NO-ERROR.
        IF AVAILABLE ttItem THEN DO:
            /* Validate price */
            IF ttItem.Price = 0 THEN DO:
                isValid = FALSE.
                errorMessage = "Price cannot be empty".
                RETURN isValid.
            END.
            
            /* Validate total value on hand */
            dTotal = ttItem.OnHand * ttItem.Price.
            IF dTotal > MaxOnHandValue THEN DO:
                isValid = FALSE.
                errorMessage = SUBSTITUTE("Total value onhand will be &1, should not be larger than &2",
                                          dTotal, MaxOnHandValue).
            END.
        END.
        
        RETURN isValid.
    END METHOD.

END CLASS.

