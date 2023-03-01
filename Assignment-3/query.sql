with validCityLocationId as
(
    select p1.id
    from Place p1, Place p2
    where p2.name = :country_name
    and p1.partofplaceid = p2.id
), validPersonId as
(
    select distinct Person.id
    from Person, validCityLocationId
    where Person.LocationCityId = validCityLocationId.id
), validForums as
(
    select distinct f1.id
    from Forum f1, validPersonId as v1
    where f1.ModeratorPersonId = v1.id
), validPosts as
(
    select distinct p1.id as postid, v1.id as forumid
    from validForums v1, Post p1
    where v1.id = p1.ContainerForumId
), relevantPostTagTable as
(
    select distinct t1.postid, t1.tagid
    from Post_hasTag_Tag as t1, Tag as t2, TagClass as t3
    where t1.tagid = t2.id
    and t2.TypeTagClassId = t3.id
    and t3.name = :tagclass
), tagForumTableTemp as
(
    select distinct v1.forumid, v1.postid, v2.tagid
    from validPosts as v1, relevantPostTagTable as v2
    where v1.postid = v2.postid
), tagForumTable as
(
    select distinct forumid, tagid, count(*) as count
    from tagForumTableTemp
    group by forumid, tagid
), maxTagTable as
(
    select t1.forumid, t1.tagid, t1.count
    from tagForumTable t1
    join (
        select distinct forumid, max(count) as maxCount
        from tagForumTable
        group by forumid
    ) t2
    on t1.forumid = t2.forumid
    and t1.count = t2.maxCount
), forumName as
(
    select forumid, title as forumtitle, tagid, count
    from maxTagTable, Forum
    where maxTagTable.forumid = Forum.id
), tagName as
(
    select forumid, forumtitle, name as mostpopulartagname, count
    from forumName, Tag
    where forumName.tagid = Tag.id
)
select distinct *
from tagName
order by count desc, forumid, forumtitle, mostpopulartagname;
