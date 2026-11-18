@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Expense Category Value Help'
@ObjectModel.resultSet.sizeCategory: #XS



define view entity ZI_KF_EC_CATEGORY_VH
  as select from DDCDS_CUSTOMER_DOMAIN_VALUE_T(
    p_domain_name: 'ZKF_EC_CATEGORY'
  )
{   @UI.hidden: true
    key domain_name,
    @UI.hidden: true
    key value_position,
    @UI.hidden: true
    @Semantics.language: true
    key language,
    
    
    @UI.textArrangement: #TEXT_ONLY
    @ObjectModel.text.element: [ 'CategoryText' ]
    value_low as Category,
    
    @UI.hidden: true
    @Semantics.text: true
    text as CategoryText
}
where language = $session.system_language
