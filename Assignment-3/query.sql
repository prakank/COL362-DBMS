-- P4 --
-- create index idx_comment_id on comment(id);
create index idx_comment_postid on comment(parentpostid);
create index idx_comment_commentid on comment(parentcommentid);
-- create index idx_post_hashastag_id on Post_hasTag_Tag(tagid);
-- create index idx_comment_hashastag_id on Comment_hasTag_Tag(tagid);
create index idx_post_hashastag_postid on Post_hasTag_Tag(postid);
create index idx_comment_hashastag_commentid on Comment_hasTag_Tag(commentid);
create index idx_tag_id on Tag(id);

-- Q4 --
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


-- C4 --
-- drop index idx_comment_id;
drop index idx_comment_postid;
drop index idx_comment_commentid;
-- drop index idx_post_hashastag_id;
-- drop index idx_comment_hashastag_id;
drop index idx_post_hashastag_postid;
drop index idx_comment_hashastag_commentid;
drop index idx_tag_id;
