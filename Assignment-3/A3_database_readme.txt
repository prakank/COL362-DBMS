The Social Network Graph Database

Data Tables
--------------------------------------------------------------------------
--  Organisation table
id                     Unique Id of the Organisation
type                   Signifies the type of it whether it is company or university      
name                   Name of the Organisation
url text               URL of the Organisation (dbpedia link)
LocationPlaceId        Id of the place where it is located
------------------------------------------------------------------------------
--  Place Table
id                     Unique Id of a Place
name                   Name of the Place 
url                    URL of the Place (dbpedia link)
type                   Type of the Place whether it is city, country or continent
PartOfPlaceId          Id of the place to whom this place is a part of
------------------------------------------------------------------------------
--  Tag table
id                     Unique Id of a tag
name                   Name of the tag                
url                    URL of the Tag
TypeTagClassId         Id of the tagclass to which the tag belongsx1
------------------------------------------------------------------------------
--  TagClass Table
id                     Unique Id of a tagclass
name                   Name of the tagclass
url                    URL of the tagclass
SubclassOfTagClassId   Id of the tagclass to whom this tagclass is a subclass of (As an example Person is a subclass of Agent which is a subclass of Thing)
------------------------------------------------------------------------------
--  Person Table
creationDate           Date on which the person created an account on the social network
creationTime           Time at which the person created an account on the social network
id                     Unique Id of a Person               
firstName              First Name
lastName               Last Name
gender                 Gender
birthday               Birth Date
locationIP             The IP of the location from which the person was registered to the social network.
browserUsed            The browser used by the person when he/she registered to the social network.
LocationCityId         The id of the city where the person resides
speaks                 The set of languages the person speaks seperated by a ; symbol
email                  The set of emails the person has (cardinality: at least one) seperated by a ; symbol
------------------------------------------------------------------------------
--  Forum table
creationDate           Date on which the Forum was created
creationTime           Time at which the Forum was created
id                     Unique Id of the Forum
title                  Title Name of the Forum
ModeratorPersonId      Id of the Person who moderates the forum
------------------------------------------------------------------------------
--  Post table
creationDate           The date on which the post was created
creationTime           The time at which the post was created
id                     The unique id of a post
imageFile              The link to the imageFile of the post
locationIP             The IP of the location from which the post was created
browserUsed            The browser used by the Person to create the post
language               The language in which the post was created
content                The content of the post
length                 The length of the post
CreatorPersonId        The id of the creator of the post
ContainerForumId       The forum to which the post belongs
LocationCountryId      The country from which the post was created
------------------------------------------------------------------------------
--  Comment table
creationDate           The date on which the Comment was created
creationTime           The time at which the Comment was created
id                     The unique id of a comment
locationIP             The IP of the location from which the comment was created
browserUsed            The browser used by the Person to create the comment
content                The content of the comment
length                 The length of the comment
CreatorPersonId        The id of the creator of the comment
LocationCountryId      The country from which the comment was created
ParentPostId           The post in whose response the comment was created
ParentCommentId        The comment in whose response the comment was created
------------------------------------------------------------------------------
-- Comment_hasTag_Tag table
--  Comment table
creationDate           The date on which the Comment was created
creationTime           The time at which the Comment was created
CommentId              The Id of the comment
TagId                  The Id of the tag
------------------------------------------------------------------------------
-- Post_hasTag_Tag table
creationDate           The date on which the Post was created
creationTime           The time at which the Post was created
PostId                 The Id of the post
TagId                  The Id of the tag
------------------------------------------------------------------------------
-- Forum_hasMember_Person table
creationDate           The date on which the person joined the forum
creationTime           The time at which the person joined the forum
ForumId                The id of the forum
PersonId               The id of the person
------------------------------------------------------------------------------
-- Forum_hasTag_Tag table
creationDate           The date on which the tag was created in the forum
creationTime           The time at which the tag was created in the forum
ForumId                The id of the forum
TagId                  The id of the tag
------------------------------------------------------------------------------
-- Person_hasInterest_Tag table
creationDate           The date on which the person created an account on the social network
creationTime           The date on which the person created an account on the social network
PersonId               The id of the person
TagId                  The tag of the person
------------------------------------------------------------------------------
-- Person_likes_Comment table
creationDate           The date on which person liked a comment
creationTime           The time at which person liked a comment
PersonId               The id of the person
CommentId              The id of the comment
------------------------------------------------------------------------------
-- Person_likes_Post table
creationDate           The date on which person liked a post
creationTime           The time at which person liked a post
PersonId               The id of the person
PostId                 The id of the post
------------------------------------------------------------------------------
-- Person_studyAt_University table
creationDate            The date on which the person created an account on the social network
creationTime            The time at which the person created an account on the social network
PersonId                The id of the person   
UniversityId            The id of the Organisation (university) in which the person works
classYear               The class year in which the person graduated from the univ
------------------------------------------------------------------------------
-- Person_workAt_Company table
creationDate            The date on which the person created an account on the social network
creationTime            The time at which the person created an account on the social network
PersonId                The id of the person
CompanyId               The id of the Organisation (company) in which the person works
workFrom                The year from which the person works in that company

------------------------------------------------------------------------------
-- Person_knows_Person table
creationDate           The date on which a person knew another person on the social network
creationTime           The time at which a person knew another person on the social network
Person1id              The id of one of the persons
Person2id              The id of the other person