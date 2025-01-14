﻿using Core.DataAccess;
using Entities.Concrete;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DataAccess.Abstract
{
    public interface IVideoDal : IEntityRepository<Video>
    {
        List<Video> GetVideosByCourseId(int courseId);
        List<Video> GetVideosBySectionId(int sectionId); // Özel bir metot
    }
}
