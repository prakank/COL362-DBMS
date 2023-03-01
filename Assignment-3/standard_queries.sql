-- 3 --

-- Approach 1

with TagDateTable as
(
    select Post.creationdate, TagId
    from Post, Post_hasTag_Tag
    where Post.creationdate >= :begindate
    and Post.creationdate <= :enddate
    and Post.creationdate = Post_hasTag_Tag.creationdate
    and Post.creationtime = Post_hasTag_Tag.creationtime
    and id = Postid
    union
    select Comment.creationdate, TagId
    from Comment, Comment_hasTag_Tag
    where Comment.creationdate >= :begindate
    and Comment.creationdate <= :enddate
    and Comment.creationdate = Comment_hasTag_Tag.creationdate
    and Comment.creationtime = Comment_hasTag_Tag.creationtime
    and id = Commentid
), firstInterval as
(
    select TagId, count(*) as msgCount
    from TagDateTable
    where creationdate >= :begindate
    and creationdate <= :middate
    group by TagId
), secondInterval as
(
    select TagId, count(*) as msgCount
    from TagDateTable
    where creationdate >= :middate
    and creationdate <= :enddate
    group by TagId
), validTags as
(
    select firstInterval.TagId
    from firstInterval, secondInterval
    where firstInterval.msgCount >= 5*secondInterval.msgCount
    and firstInterval.TagId = secondInterval.TagId
    and secondInterval.msgCount >= 1
), validTagClass as
(
    select Tag.TypeTagClassId as tagid, TagClass.name as tagclassname
    from validTags, Tag, TagClass
    where validTags.TagId = Tag.Id
    and Tag.TypeTagClassId = TagClass.Id
)
select tagclassname, count(*) as count
from validTagClass
group by tagclassname
order by count desc, tagclassname;





-- Approach 2

with TagDateTable as
(
    select Post.creationdate, TagId
    from Post, Post_hasTag_Tag
    where Post.creationdate >= :begindate
    and Post.creationdate <= :enddate
    and Post.creationdate = Post_hasTag_Tag.creationdate
    and Post.creationtime = Post_hasTag_Tag.creationtime
    and id = Postid
    union
    select Comment.creationdate, TagId
    from Comment, Comment_hasTag_Tag
    where Comment.creationdate >= :begindate
    and Comment.creationdate <= :enddate
    and Comment.creationdate = Comment_hasTag_Tag.creationdate
    and Comment.creationtime = Comment_hasTag_Tag.creationtime
    and id = Commentid
), firstIntervalTemp as
(
    select TagId, count(*) as msgCount
    from TagDateTable
    where creationdate >= :begindate
    and creationdate <= :middate
    group by TagId
), secondIntervalTemp as
(
    select TagId, count(*) as msgCount
    from TagDateTable
    where creationdate >= :middate
    and creationdate <= :enddate
    group by TagId
), firstInterval as
(
    select TypeTagClassId as tagid, msgCount
    from firstIntervalTemp, Tag
    where firstIntervalTemp.tagid = Tag.id
), secondInterval as
(
    select TypeTagClassId as tagid, msgCount
    from secondIntervalTemp, Tag
    where secondIntervalTemp.tagid = Tag.id
), validTags as
(
    select firstInterval.TagId
    from firstInterval, secondInterval
    where firstInterval.msgCount >= 5*secondInterval.msgCount
    and firstInterval.TagId = secondInterval.TagId
    and secondInterval.msgCount >= 1
), validTagClass as
(
    select validTags.tagid, TagClass.name as tagclassname
    from validTags, TagClass
    where validTags.TagId = TagClass.Id
)
select tagclassname, count(*) as count
from validTagClass
group by tagclassname
order by count desc, tagclassname;




-- 4 --
with t1 as
(
    select id, parentpostid
    from comment
), postReply as
(
    select parentpostid as msgid, count(*) as replyComments
    from t1
    group by parentpostid
    having count(*) >= :X
), t2 as 
(
    select id, parentcommentid
    from comment
), commentReply as
(
    select parentcommentid as msgid, count(*) as replyComments
    from t2
    group by parentcommentid
    having count(*) >= :X
), tagAttachedpost as
(
    select msgid, tagid
    from postReply, Post_hasTag_Tag
    where postReply.msgid = Post_hasTag_Tag.postid
), tagAttachedcomment as
(
    select msgid, tagid
    from commentReply, Comment_hasTag_Tag
    where commentReply.msgid = Comment_hasTag_Tag.commentid
), tagAttachedTemp as
(
    select tagid, count(*) as num
    from tagAttachedpost
    group by tagid
    union all
    select tagid, count(*) as num
    from tagAttachedcomment
    group by tagid
), tagAttached as
(
    select tagid, sum(num) as count
    from tagAttachedTemp
    group by tagid
)
select Tag.name as tagname, count
from tagAttached, Tag
where tagAttached.tagid = Tag.id
order by count desc, tagname
limit 10;


-- 5 --
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
