Class model.Person Extends (%RegisteredObject, %JSON.Adaptor)
{

/// Person's IDCard number.
Property IDCard As %String(%JSONFIELDNAME = "IDNum", PATTERN = "18N") [ Required ];

/// Name of the person.
Property Name As %String;

/// Person's Relationships.
Property Relationships As list Of model.Relationship;

}
